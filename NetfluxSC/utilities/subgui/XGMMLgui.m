function varargout = XGMMLgui(varargin)
% GUI for XGMML export
%      XGMMLgui, by itself, creates a new XGMMLgui or raises the existing
%      singleton*.
%
%      H = XGMMLgui returns the handle to a new XGMMLgui or the handle to
%      the existing singleton*.
%
%      XGMMLgui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in XGMMLgui.M with the given input arguments.
%
%      XGMMLgui('Property','Value',...) creates a new XGMMLgui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before XGMMLgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to XGMMLgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help XGMMLgui

% Last Modified by GUIDE v2.5 25-Jun-2014 10:01:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @XGMMLgui_OpeningFcn, ...
                   'gui_OutputFcn',  @XGMMLgui_OutputFcn, ...
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


% --- Executes just before XGMMLgui is made visible.
function XGMMLgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to XGMMLgui (see VARARGIN)

set(hObject, 'name', 'Export XGMML');
set(hObject, 'Color', [.8 .9 .9]);
set(handles.text1, 'BackgroundColor', [.8 .9 .9]);
set(handles.text2, 'BackgroundColor', [.8 .9 .9]);
movegui(hObject, 'center');

% Choose default command line output for XGMMLgui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes XGMMLgui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = XGMMLgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Assign output from handles structure
try 
    fnames.output = get(handles.outputfname, 'String');
    fnames.reference = get(handles.referencefname, 'String');
    fnames.userCanceled = false;
    varargout{1} = fnames;
    delete(handles.figure1);
catch e % something went wrong
    fnames.output = '';
    fnames.reference = '';
    fnames.userCanceled = true;
    varargout{1} = fnames;
end
    

function outputfname_Callback(hObject, eventdata, handles)
% hObject    handle to outputfname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of outputfname as text
%        str2double(get(hObject,'String')) returns contents of outputfname as a double


% --- Executes during object creation, after setting all properties.
function outputfname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to outputfname (see GCBO)
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


% --- Executes on button press in setOutputfile.
function setOutputfile_Callback(hObject, eventdata, handles)
% hObject    handle to setOutputfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fname, pname] = uiputfile('*.xgmml', 'Save As');
set(handles.outputfname, 'string', fullfile(pname,fname));


% --- Executes on button press in getReferencefile.
function getReferencefile_Callback(hObject, eventdata, handles)
% hObject    handle to getReferencefile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fname, pname] = uigetfile('*.xgmml', 'Select Reference Model');
if fname ~= 0
    set(handles.referencefname, 'string', fullfile(pname,fname));
end

% --- Executes on button press in cancelButton.
function cancelButton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1);

% --- Executes on button press in ExportButton.
function ExportButton_Callback(hObject, eventdata, handles)
% hObject    handle to ExportButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1);


function referencefname_Callback(hObject, eventdata, handles)
% hObject    handle to referencefname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of referencefname as text
%        str2double(get(hObject,'String')) returns contents of referencefname as a double


% --- Executes during object creation, after setting all properties.
function referencefname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to referencefname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
