function writeFunctionSignatureJSON(file)
% Given a matlab code file, guess the inputs to the file and write a
% function signature object to functionSignatures.json, to allow for tab
% completion. 
% 
% Example: writeFunctionSignatures('sf_pre/+Vicon/C3DtoMOT.m')
% Creates/Edits: sf_pre/functionSignatures.json
% 

    file = GetFullPath(file);
    folder = fileparts(file);
    % returns a string of a function signature object that must be added to
    % the list in functionSignatures.json
    json = generateFunctionSignatureJSON(file);
    % determine the folder that the json file should be placed in based on
    % the returned string. Generally, it should be placed in the same
    % directory as the function, but for classes/packages, it should be
    % placed in the same level as the folder containing the class/package
    fnName = strtok(json, newline);
    fnName = fnName(2:end-2);
    nClasses = sum(fnName == '.');
    for idx = 1:nClasses
        folder = fileparts(folder);
    end
    fnSigs = fullfile(folder, 'functionSignatures.json');
    fnSigData = json;
    % concatenate the function signature object with any existing ones, and
    % write the output to the file
    if exist(fnSigs, 'file')
        fnSigData = fileread(fnSigs);
        openBrace = find(fnSigData == '{', 1);
        closeBrace = find(fnSigData == '}', 1, 'last');
        fnSigData = fnSigData(openBrace+1:closeBrace-1);
        fnSigData = strjoin({fnSigData, json}, ',');
    end
    fnSigData = ['{', newline, fnSigData, newline, '}'];
    fh = fopen(fnSigs, 'w');
    fprintf(fh, '%s', fnSigData);
    fclose(fh);
    % matlab built in function to make sure the file was written with
    % proper syntax
    validateFunctionSignaturesJSON(fnSigs);
end

%% Helper Functions

function json = generateFunctionSignatureJSON(file)
    % return a string of a function signature object based on a matlab file
    
    file = GetFullPath(file);
    % get the entire data of the code
    code = fileread(file);
    lines = splitlines(code);
    % get the line that has the function signature
    sig = lines(startsWith(strtrim(lines), 'function'));
    sig = sig{1};
    % sig contains something like 'function writeFunctionSignatureJSON(file)'
    % split the part inside the parentheses  based on commas to determine
    % the variable names
    inputs = sig(strfind(sig, '(')+1:strfind(sig, ')')-1);
    inputs = inputs(inputs ~= ' ');
    inputs = split(inputs, ',');
    reqInputs = ~strcmp(inputs, 'varargin');
    hasOpt = ~all(reqInputs);
    %% required inputs
    inputs = inputs(reqInputs);
    % objs will contain every input object of the function
    objs = [];
    for idx = 1:length(inputs)
        input = inputs{idx};
        objs = [objs, {inputObject(input, 'Kind', 'required')}];
    end

    %% ordered inputs
    orderedVars = lines(contains(lines, 'addOptional'));
    for idx = 1:length(orderedVars)
        % from the line containing 'addOptional' identify the name of the
        % variable and create an optional input object, and add it to objs
        orderedVar = orderedVars{idx};
        startIdx = strfind(orderedVar, 'addOptional') + length('addOptional');
        orderedVar = orderedVar(startIdx:end);
        startIdx = strfind(orderedVar, '''');
        if length(startIdx) < 2
            continue;
        end
        % assuming there are two quotes in the line, the variable name will
        % be between the first and second
        orderedVar = orderedVar(startIdx(1)+1:startIdx(2)-1);
        objs = [objs, {inputObject(orderedVar, 'Kind', 'ordered')}];
    end


    %% name value pairs
    nameValueVars = lines(contains(lines, 'addParameter'));
    for idx = 1:length(nameValueVars)
        nv = nameValueVars{idx};
        % based on the line containing addParameter, find the variable name
        % and create a name-value input object, and add it to objs
        startIdx = strfind(nv, 'addParameter') + length('addParameter');
        nv = nv(startIdx:end);
        startIdx = strfind(nv, '''');
        if length(startIdx) < 2
            continue;
        end
        nv = nv(startIdx(1)+1:startIdx(2)-1);
        objs = [objs, {inputObject(nv, 'Kind', 'namevalue')}];
    end
    if isempty(orderedVars) && isempty(nameValueVars) && hasOpt
        warning('This function may have optional inputs that could not be automatically determined.')
    end

    %% get function name
    file = strrep(file, '.m', '');
    parts = split(file, filesep);
    % determine the name of the function, including any class/package
    % specifiers 
    fnName = parts{end};
    for idx = length(parts)-1:-1:1
        p = parts{idx};
        if startsWith(p, {'@', '+'})
            p = strrep(p, '@', '');
            p = strrep(p, '+', '');
            fnName = [p '.' fnName];
        else
            break;
        end
    end
    % fnName should be something like
    % 'Outerclass.Innerclass.InnerPackage.InnermostPackage.functionname'
    % for as many classes and packages are containing the function
    
    % create the function signature object from the cell array of input
    % objects and return the resulting string
    json = fnSigObj(fnName, objs);
end

function str = fnSigObj(fname, inputs)
    % for a cell array of input objects, create a function signature object
    list = ['[', newline, strjoin(inputs, ',\n'), newline, ']'];
    str = sprintf('"%s":\n{\n"inputs":\n%s\n}', fname, list);
end

function val = inputObject(name, varargin)
    % returns a string representing an input object, which should be added
    % to the list of input objects in the function signature object
    p = inputParser;
    p.addParameter('Kind', 'required');
    p.addParameter('Type', '@(~)true');
    p.addParameter('Repeating', 'false');
    p.parse(varargin{:});
    kind = p.Results.Kind;
    type = p.Results.Type;
    repeating = p.Results.Repeating;

    val = sprintf('{"name":"%s","kind":"%s","type":"%s","repeating":%s}', name, kind, type, repeating);
end
