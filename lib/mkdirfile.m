function mkdirfile(filepath)
% make the directory for the filepath if it does not exist.
% mkdirfile(filepath)
	a=fileparts(filepath);
	if ~exist(a,'dir')
		mkdir(a);
	end
end

