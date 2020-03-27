function files = matchFiles(varargin)
% files = matchFiles(dirArg)
% files = matchFiles(filepart1, ..., filepartN)
% Returns a cell array containing the full path of all files and folders
% that would be matched by dir(dirArg). Uses the same syntax as dir(),
% including using '**' to recurse through subdirectories. If multiple
% inputs are given, they will be combined with fullfile() before being
% passed to dir.
% Example usages: 
% files = matchFiles('C:/');
% files = matchFiles('./*.txt');
% files = matchFiles(folder, '*.txt');
% files = matchFiles(folder, '**/*.txt');

    files = dir(fullfile(varargin{:}));
    files = arrayfun(@(x) {fullfile(x.folder, x.name)}, files);
    if isempty(files)
        files = {};
    end
end
