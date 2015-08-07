function varargout = SIFgui(varargin)
% GUI for SIF conversion tool
%      SIFgui, by itself, creates a new SIFgui or raises the existing
%      singleton*.
%
%      H = SIFgui returns the handle to a new SIFgui or the handle to
%      the existing singleton*.
%
%      SIFgui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIFgui.M with the given input arguments.
%
%      SIFgui('Property','Value',...) creates a new SIFgui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SIFgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SIFgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SIFgui

% Last Modified by GUIDE v2.5 01-Jul-2014 14:43:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SIFgui_OpeningFcn, ...
                   'gui_OutputFcn',  @SIFgui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SIFgui is made visible.
function SIFgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SIFgui (see VARARGIN)

set(hObject, 'name', 'Convert SIF');
set(hObject, 'Color', [.8 .9 .9]);
set(handles.text1, 'BackgroundColor', [.8 .9 .9]);
set(handles.text2, 'BackgroundColor', [.8 .9 .9]);
movegui(hObject, 'center');

% Choose default command line output for SIFgui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SIFgui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SIFgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Assign output from handles structure
try 
    fnames.sif = get(handles.SIFname, 'String');
    if exist(fnames.sif,'file') == 0
        error('Could not find specified SIF');
    end
    fnames.outputname = get(handles.xlsxname, 'String');
    
    [pathstr, name, ext] = fileparts(fnames.outputname);
    
    if strcmp(fnames.outputname,'');
        error('Must specify output .xlsx');
    end

    fnames.userCanceled = false;
    varargout{1} = fnames;
    delete(handles.figure1);
catch e % something went wrong
    fnames.sif = '';
    fnames.outputname = '';
    fnames.userCanceled = true;
    varargout{1} = fnames;
    try
        delete(handels.figure1);
    catch
    end
end
    

function SIFname_Callback(hObject, eventdata, handles)
% hObject    handle to SIFname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SIFname as text
%        str2double(get(hObject,'String')) returns contents of SIFname as a double


% --- Executes during object creation, after setting all properties.
function SIFname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SIFname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in setSIF.
function setSIF_Callback(hObject, eventdata, handles)
% hObject    handle to setSIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fname, pname] = uigetfile('*.sif', 'Select SIF file');
set(handles.SIFname, 'string', fullfile(pname,fname));


% --- Executes on button press in setOutput.
function setOutput_Callback(hObject, eventdata, handles)
% hObject    handle to setOutput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fname, pname] = uiputfile('*.xlsx', 'Save Output File As');
if fname ~= 0
    set(handles.xlsxname, 'string', fullfile(pname,fname));
end

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1);

% --- Executes on button press in convertButton.
function convertButton_Callback(hObject, eventdata, handles)
% hObject    handle to convertButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1);


function xlsxname_Callback(hObject, eventdata, handles)
% hObject    handle to xlsxname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xlsxname as text
%        str2double(get(hObject,'String')) returns contents of xlsxname as a double


% --- Executes during object creation, after setting all properties.
function xlsxname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xlsxname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on xlsxname and none of its controls.
function xlsxname_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to xlsxname (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
