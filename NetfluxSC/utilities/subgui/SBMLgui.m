function varargout = SBMLgui(varargin)
% GUI for SBML conversion tool
%      SBMLgui, by itself, creates a new SBMLgui or raises the existing
%      singleton*.
%
%      H = SBMLgui returns the handle to a new SBMLgui or the handle to
%      the existing singleton*.
%
%      SBMLgui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SBMLgui.M with the given input arguments.
%
%      SBMLgui('Property','Value',...) creates a new SBMLgui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SBMLgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SBMLgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SBMLgui

% Last Modified by GUIDE v2.5 01-Jul-2014 10:53:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SBMLgui_OpeningFcn, ...
                   'gui_OutputFcn',  @SBMLgui_OutputFcn, ...
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


% --- Executes just before SBMLgui is made visible.
function SBMLgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SBMLgui (see VARARGIN)

set(hObject, 'name', 'Convert SBML-QUAL');
set(hObject, 'Color', [.8 .9 .9]);
set(handles.text1, 'BackgroundColor', [.8 .9 .9]);
set(handles.text2, 'BackgroundColor', [.8 .9 .9]);
movegui(hObject, 'center');

% Choose default command line output for SBMLgui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SBMLgui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SBMLgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Assign output from handles structure
try 
    fnames.xml = get(handles.SBMLname, 'String');
    fnames.outputfolder = get(handles.outputFolder, 'String');
    fnames.userCanceled = false;
    varargout{1} = fnames;
    delete(handles.figure1);
catch e % something went wrong
    fnames.xml = '';
    fnames.outputfolder = '';
    fnames.userCanceled = true;
    varargout{1} = fnames;
    try
        delete(handles.figure1);
    catch
    end
end
    

function SBMLname_Callback(hObject, eventdata, handles)
% hObject    handle to SBMLname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SBMLname as text
%        str2double(get(hObject,'String')) returns contents of SBMLname as a double


% --- Executes during object creation, after setting all properties.
function SBMLname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SBMLname (see GCBO)
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


% --- Executes on button press in setSBML.
function setSBML_Callback(hObject, eventdata, handles)
% hObject    handle to setSBML (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fname, pname] = uigetfile('*.xml;*.sbml', 'Select SBML-QUAL file');
set(handles.SBMLname, 'string', fullfile(pname,fname));


% --- Executes on button press in setOutputFolder.
function setOutputFolder_Callback(hObject, eventdata, handles)
% hObject    handle to setOutputFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[folderName] = uigetdir(cd,'Select Output Folder');
if folderName ~= 0
    set(handles.outputFolder, 'string', folderName);
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

function outputFolder_Callback(hObject, eventdata, handles)
% hObject    handle to outputFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of outputFolder as text
%        str2double(get(hObject,'String')) returns contents of outputFolder as a double


% --- Executes during object creation, after setting all properties.
function outputFolder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to outputFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
