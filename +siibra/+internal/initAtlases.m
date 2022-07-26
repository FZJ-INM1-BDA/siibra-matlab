function atlases = initAtlases(clear_cache)
arguments
    clear_cache (1, 1) logical
end
    cached_file_name = '+siibra/cache/atlases.mat';
    if clear_cache || ~isfile(cached_file_name)
        apiEndpoint = "https://siibra-api-latest.apps-dev.hbp.eu/v1_0/";
        %apiEndpoint = "https://siibra-api-latest.apps-dev.hbp.eu/v2_0/";
        options = weboptions;
        options.Timeout = 30;
        atlases_json = webread(apiEndpoint + "atlases");
        atlases = siibra.items.Atlas.empty;
        for atlas_row = 1:numel(atlases_json)
            atlas = siibra.items.Atlas(atlases_json(atlas_row));
            atlases(end + 1) = atlas;
        end
        save(cached_file_name, 'atlases');
    else
        load(cached_file_name, 'atlases');
    end
end