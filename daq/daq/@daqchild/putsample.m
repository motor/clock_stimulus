function putsample(varargin)
%PUTSAMPLE Immediately output single sample to channel group.
%
%    PUTSAMPLE(OBJ, DATA) immediately outputs a row vector, DATA, containing
%    one sample for each channel contained by analog output object, OBJ.
%    OBJ must be a 1-by-1 analog output object.
%
%    PUTSAMPLE is valid for analog output processes only and can be called 
%    when OBJ is not running.
%
%    PUTSAMPLE is not supported for sound cards or for Agilent Technologies 
%    hardware.
% 
%    See also DAQHELP, PUTDATA.
%

%    CP 4-10-98
%    Copyright 1998-2003 The MathWorks, Inc.
%    $Revision: 1.10.2.4 $  $Date: 2003/08/29 04:40:33 $

error('daq:putsample:invalidtype', 'Wrong object type passed to PUTSAMPLE.  Use the object''s parent.');
