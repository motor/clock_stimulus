function putvalue(obj, data)
%PUTVALUE Write line values.
%
%    PUTVALUE(OBJ,DATA) write the data, DATA, to the digital I/O lines,
%    OBJ, or to the lines contained by digital I/O object, OBJ.
% 
%    DATA can be specified as either a decimal or a binvec value.   
%    A binvec value is a binary vector which is written with the  
%    least significant bit (LSB) as the leftmost vector element and 
%    the most significant bit (MSB) as the rightmost vector element.
%    If OBJ is a digital I/O object then the LSB is OBJ.Line(1) and
%    the MSB is OBJ.Line(end).
%
%    If OBJ is a digital I/O object which contains lines from a port-
%    configurable device then all lines will be written to even if they 
%    are not contained by the device object.  This is an inherent 
%    restriction of a port-configurable device.
%
%    An error will be returned if data is written to an input line.
%
%    If a decimal value is written to a digital I/O object and the value
%    is too large to be represented by the object, then an error is 
%    returned.  Otherwise the word is padded with zeros.
%
%    Example:
%       dio = digitalio('nidaq', 1);
%       hline = addline(dio, 0:3, 'out');
%       putvalue(dio, 8)
%       putvalue(dio, [0 0 0 0])
%       putvalue(dio.Line(1:4), [0 1 0 1])
%
%    See also DIGITALIO, ADDLINE, GETVALUE, BINVEC2DEC, DEC2BINVEC,
%    DAQHELP.
%

%    MP 2-19-99
%    Copyright 1998-2003 The MathWorks, Inc.
%    $Revision: 1.7.2.5 $  $Date: 2004/12/01 19:47:43 $

% Check the class of data.
if ( isempty(data) || (~isnumeric(data) && ~islogical(data)))
    error('daq:putvalue:invaliddata', 'DATA must be either a decimal or a binvec value.');
end

% Output the data.
try
    % Get the indices of these lines.
    lineIndices = get(obj,'Index');
    if ( iscell(lineIndices) )
        lineIndices = [lineIndices{:}];
    end
   
    % Get the parent of these lines. All the lines will have the same
    % parent.
    parent = get(obj, 'Parent');
    if ( iscell(parent) )
        parent = parent{1};
    end
      
    % Put the values of the specified lines.
    parentuddobj = daqgetfield(parent,'uddobject');
    putvalue(parentuddobj,data,lineIndices);
catch
    rethrow(lasterror);
end