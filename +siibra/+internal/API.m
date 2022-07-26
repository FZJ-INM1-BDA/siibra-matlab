classdef API
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant=true)
        Endpoint = "https://siibra-api-stable.apps.hbp.eu/v1_0/"
    end

    methods (Static)
        function link = absoluteLink(relativeLink)
            link = siibra.internal.API.Endpoint + relativeLink;
        end
    end
    
end

