function obj = subsasgn(obj, Struct, Value)
%SUBSASGN Assign into data acquisition object.
%
%    Supported syntax for device objects:
%    ai.samplerate=1000;           calls set(ai,'samplerate',1000);
%    ai.channel = ch;              calls set(ai,'channel',ch);
%    ai.channel.units = 'Temp';    calls set(get(ai, 'Channel'), 'Units', 'Temp');
%    ai.channel(1:3) = ch;         calls set(get(ai, Channel, 1:3), 'Channel', ch);
%    ai.channel(3).Units='Temp';   calls set(get(ai, 'Channel', 3), 'Units', 'Temp');
%               
%    Supported syntax for channels or lines:
%    aic.Units = 'Degrees';    calls  set(aic, 'Units', 'Degrees');
%    aic(1:2).Units = Degrees; calls  set(aic(1:2), 'Units', 'Degrees');
%    aic(1:2) = ch;            calls  set(get(aic, 'Parent'), 'Channel', ch);
%
%    See also DAQDEVICE/SET, ANALOGINPUT, ANALOGOUTPUT, DIGITALIO, PROPINFO,
%    ADDCHANNEL, ADDLINE.
%

%    MP 3-26-98
%    Copyright 1998-2004 The MathWorks, Inc.
%    $Revision: 1.10.2.5 $  $Date: 2004/12/01 19:46:02 $

if isempty(obj)
   % Ex. chan(1) = addchannel(ai, 1);
   if isequal(Struct.type, '()') && isequal(Struct.subs{1}, 1:length(Value))
      obj = Value;
      return;
   elseif ~isa(obj,'aichannel') && ~isa(Struct.subs,'cell'),
      obj=builtin('subsasgn',obj,Struct,Value);
      return
   elseif length(Value) ~= length(Struct.subs{1})
      % Ex. chan(1) = addchannel(ai, 1:2);
      error('daq:subsasgn:invalidassignment', 'In an assignment A(I)=B, the number of elements in B and I must be the same.');
   elseif Struct.subs{1}(1) <= 0
      error('daq:subsasgn:invalidindex', 'Index into matrix is negative or zero.');
   else
      % Ex. chan(2) = addchannel(ai, 1); where chan is originally empty.
      error('daq:subsasgn:invalidindex', 'Gaps are not allowed in channel indexing.');
   end
elseif ~isa(obj,'aichannel'),
   obj=builtin('subsasgn',obj,Struct,Value);
   return
end

% Initialize variables
StructL = length(Struct);

% Define possible error messages
error1 = 'Invalid syntax.  For help type ''daqhelp set''.';

% Parse the input into PROP1 and INDEX.
try
   [prop1, index, errflag] = daqgate('privateparsechild',obj,Struct);
catch
   error('daq:subsasgn:unexpected', lasterr)
end

% Return original object if the index is empty.
if errflag ==2 
   return;
end

% Error if an error occurred in privateparsechild.
if errflag
   error('daq:subsasgn:unexpected', lasterr);
end

% From the parsed input, obtain the requested information.
switch StructL
case 1
   % It is not possible to assign different values to multiple objects
   % with the dot notation.  However, this can be done with SET
   % chan.ChannelName = {'temp1';'temp2';temp3'}; should fail
   % chan.SensorRange = [-5 5]; should work.
   if length(obj) > 1 && iscell(Value)
      error('daq:subsasgn:invalidsyntax', error1);
   end

   % Take care of the valid cases.
   if ~isempty(prop1)       
      % chan.SensorRange = [-5 5];
      try
         set(obj,prop1,Value);
      catch
         localCheckError;
        error('daq:subsasgn:unexpected', lasterr);
      end
   elseif ~isempty(index)   
      % chan(1:2) = chan(2:-1:1)
      try
         if isempty(Value)
            % chan(3) = [];  This doesn't delete the channel but it removes
            % the channel from the channel array.
            uddobjs = obj.uddobject;
            uddobjs(index{1}) = [];
            obj.uddobject = uddobjs;
         elseif ~all(isvalid(obj))
            error('daq:subsasgn:badparent', 'Concatenation of invalid channels or channels with different parents is not allowed.');
         elseif isequal(get(obj, 'Parent'), get(Value, 'Parent'))
            % Obj and Value have the same parent and can therefore be
            % concatenated.
            
            % Initialize variables.
            uddobjs = obj.uddobjects;
            [m,n] = size(uddobjs);
            
            if index{1}(1) == length(uddobjs)+1
               % Ex. chan is 1-by-2; chan(3) = addchannel(ai, 3);
               if (length(index{1}) == length(Value.uddobject))
                  if n == 1
                     obj.uddobject = [uddobjs; Value.uddobject];
                  elseif m == 1
                     obj.uddobject = [uddobjs Value.uddobject];
                  end
               else
                  % Ex. chan is 1-by-2; chan(3) = addchannel(ai, [3 4]);
                  error('daq:subsasgn:invalidassignment', 'In an assignment A(I)=B, the number of elements in B and I must be the same.');
               end
            elseif index{1} > length(uddobjs) + 1
               % Ex. chan is 1-by-2; chan(4) = addchannel(ai, 4);
               error('daq:subsasgn:invalidindex', 'Gaps are not allowed in channel indexing.');
            elseif length(index{1}) == length(Value.uddobject)
               % Ex. chan(1:2) = chan(2:-1:1);
               % Ex. chan(2) = chan(4); where chan is 1-by-5.
               obj.uddobject(index{1}) = Value.uddobject;
            else
               error('daq:subsasgn:invalidassignment', 'In an assignment A(I)=B, the number of elements in B and I must be the same.');
            end     
         else
            error('daq:subsasgn:badparent', 'Only objects with the same parent are permitted to be concatenated.');
         end   
      catch
         error('daq:subsasgn:unexpected', lasterr);
      end
   end
case 2
   % It is not possible to assign different values to multiple objects
   % with the dot notation.  However, this can be done with SET.
   % chan(1:3).Name = {'temp1';'temp2';'temp3'};  should fail.
   % chan(1:3).SensorRange = [-5 5]; should work.
   if length(obj) > 1 && iscell(Value)
      error('daq:subsasgn:invalidsyntax', error1);
   end
   
   % chan(1:3).SensorRange = [-5 5];
   try
      h = struct(obj);
      constr = class(obj);
      % result contains an array of channels or lines. 
      result = feval(constr, h.uddobject(index{1}(:)) );
      set(result, prop1, Value);
   catch
      localCheckError;
      error('daq:subsasgn:unexpected', lasterr);
   end
otherwise 
   error('daq:subsasgn:invalidsyntax', 'Invalid syntax: Too many subscripts.')
end

% *************************************************************************
% Remove any extra carriage returns.
function localCheckError

errmsg = lasterr;

while errmsg(end) == sprintf('\n')
   errmsg = errmsg(1:end-1);
end

lasterr(errmsg);
