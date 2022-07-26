classdef Parcellation < handle
    properties
        Id (1, 1) string
        Name (1, 1) string
        Atlas (1, :) siibra.items.Atlas
        Modality % no consistent type yet
        Desciption (1, 1) string
        RegionTree (1, 1) digraph
        Spaces (1, :) siibra.items.Space
    end

    methods
        function parcellation = Parcellation(parcellation_json, atlas)
            parcellation.Id = strcat(parcellation_json.id.kg.kgSchema, '/', parcellation_json.id.kg.kgId);
            parcellation.Name = parcellation_json.name;
            parcellation.Atlas = atlas;
            parcellation.Modality = parcellation_json.modality;

            if ~ isempty(parcellation_json.infos)
                parcellation.Desciption = parcellation_json.infos(1).description;
            end

            % link spaces from atlas
            parcellation.Spaces = siibra.items.Space.empty;
            % retrieve available spaces from atlas
            for idx = 1:numel(parcellation_json.availableSpaces)
                % store handle to space object
                for atlas_space_index = 1:numel(atlas.Spaces)
                    if isequal(atlas.Spaces(atlas_space_index).Id, parcellation_json.availableSpaces(idx).id)
                        parcellation.Spaces(end +1) = atlas.Spaces(atlas_space_index);
                    end
                end
            end
            
            % call api to get parcellation tree
            regions = webread(parcellation_json.links.regions.href);
            
            % store graph
            parcellation.RegionTree = siibra.items.Parcellation.createParcellationTree(parcellation, regions);
        end

        function map = parcellationMap(obj, spaceName)
            for idx = 1:numel(obj.Spaces)
                if obj.Spaces(idx).Name == spaceName
                    map = siibra.items.maps.ParcellationMap(obj, obj.Spaces(idx));
                end
            end
        end
       
        function region_names = findRegion(obj, region_name_query)
            region_names = obj.RegionTree.Nodes(contains(obj.RegionTree.Nodes.Name, region_name_query), 1);
        end
        function region = decodeRegion(obj, region_name_query)
            region_table = obj.findRegion(region_name_query);
            assert(height(region_table) == 1, "query was not unambiguous!")
            region = region_table.Region(1);
        end
        function region = getRegion(obj, region_name_query)
            nodeId = obj.RegionTree.findnode(region_name_query);
            region = obj.RegionTree.Nodes.Region(nodeId);
        end
        function children = getChildRegions(obj, region_name)
            nodeId = obj.RegionTree.findnode(region_name);
            childrenIds = obj.RegionTree.successors(nodeId);
            children = obj.RegionTree.Nodes.Region(childrenIds);
        end
        function parent_region = getParentRegion(obj, region_name)
            nodeId = obj.RegionTree.findnode(region_name);
            parents = obj.RegionTree.predecessors(nodeId);
            assert(length(parents) == 1, "Expect just one parent in a tree structure");
            parentId = parents(1);
            parent_region = obj.RegionTree.Nodes.Region(parentId);
        end
    end
    

    methods (Static)
        function tree = createParcellationTree(parcellation, regions)
            root.name = parcellation.Name;
            root.children = regions;
            [source, target, region] = siibra.items.Parcellation.traverseTree(parcellation, root, string.empty, string.empty, siibra.items.Region.empty);
            % append root node
            nodes = target;
            nodes(length(nodes) + 1) = root.name;
            region(length(region) + 1) = siibra.items.Region(root.name, parcellation, []);
            % make nodes unique
            [unique_nodes, unique_indices, ~] = unique(nodes);
            nodeTable = table(unique_nodes.', region(unique_indices).', 'VariableNames', ["Name", "Region"]);
            tree = digraph(source, target, zeros(length(target), 1),  nodeTable);
        end

        function [source, target, regions] = traverseTree(parcellation, root, source, target, regions)
            % Parses the parcellation tree.
            % Recursively calls itself to parse the children of the current
            % root.
            % Creates a region for each node in the parcellation tree.

            for child_num = 1:numel(root.children)
                child = root.children(child_num);
                source(length(source) + 1) = root.name;
                target(length(target) + 1) = child.name;
                regions(length(regions) + 1) = siibra.items.Region(child.name, parcellation, child.x_dataset_specs);
                [source, target, regions] = siibra.items.Parcellation.traverseTree(parcellation, child, source, target, regions);
            end
        end
    end
end