function varargout = parallelRun(fun, varargin)
% parallelRun runs a function given by fun several times in parallel using
% the specified input arguments.
% [varargout] = parallelRun(fun, varargin);
% 
% If fun is a function with the signature: [x, y] = myFunc(a, b, c);
% then parallelRun is called by: [X, Y] = parallelRun(@myFunc, A, B, C);
% where A, B, and C are cell arrays of each of the inputs a, b, and c to
% myFunc to be used for each evalution, and X and Y are cell arrays of each
% of the outputs x and y from myFunc. 
% [X{i}, Y{i}] = myFunc(A{i}, B{i}, C{i});
% If one of the inputs to myFunc should be the same between evaluations,
% the corresponding input to parallelRun can be identical to the input to
% myFunc, i.e. [X, Y] = parallelRun(@myFunc, A, B, c); if c should be the
% same between evalutions.

    try
        p = gcp();
    catch
        error(['Could not start parallel pool. You may need to ', ...
        'download and install the Parallel Computing Toolbox.']);
    end
    h = progress(0);
    for idx = 1:length(varargin{1})
        inputs = retrieveInputs(varargin, idx);
        f(idx) = parfeval(p, fun, nargout(fun), inputs{:});
    end

    nFinished = 0;
    completedIdxs = [];
    for idx = 1:length(f)
        try
            results = cell(1, nargout(fun));
            [completedIdx,results{:}] = fetchNext(f);
            completedIdxs = [completedIdxs, completedIdx];
            for j = 1:nargout(fun)
                varargout{j}{completedIdx} = results{j};
            end
            fprintf('Finished task %d.\n', completedIdx);
        catch e
            warning(e.getReport);
        end
        nFinished = nFinished + 1;
        h = progress(nFinished/length(f), h);
    end
    delete(h);
    fprintf('All tasks finished!\n');
    errored = setdiff(1:length(f), completedIdxs);
    if ~isempty(errored)
        fprintf('Error on index %d.\n', errored);
    end
end

function out = retrieveInputs(inputs, idx)
    out = cell(1, length(inputs));
    for j = 1:length(inputs)
        if ~iscell(inputs{j}) || numel(inputs{j}) == 1
            out{j} = inputs{j};
        else
            out{j} = inputs{j}{idx};
        end
    end
end
