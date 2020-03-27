function clearTemp
% Clear temp folder from opensim files
delete(fullfile(tempdir, 'tp*.trc'));
delete(fullfile(tempdir, 'tp*.mot'));
delete(fullfile(tempdir, 'tp*.osim'));
delete(fullfile(tempdir, 'tp*.xml'));
delete(fullfile(tempdir, 'tp*.sto'));
d = dir(fullfile(tempdir, 'tp*/*.sto'));
d = unique({d.folder});
cellfun(@(x)rmdir(x, 's'), d);
end
