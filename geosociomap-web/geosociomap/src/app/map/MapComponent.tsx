import React, { useEffect } from 'react';
import mapboxgl from 'mapbox-gl';
import { FeatureCollection, Point, Feature } from 'geojson'; 

type MapProps = {
  selectedQuestions: string[];
  selectedOptions: { [key: string]: string[] };
};

const MapComponent: React.FC<MapProps> = ({ selectedQuestions, selectedOptions }) => {
  useEffect(() => {
    const map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/mapbox/streets-v11',
      center: [100.523186, 13.736717],
      zoom: 10,
    });

   
    if (selectedQuestions.length > 0 && Object.keys(selectedOptions).length > 0) {
      updateDensityMap(map, selectedOptions);
    }

    return () => map.remove(); 
  }, [selectedQuestions, selectedOptions]);

  const updateDensityMap = (map: mapboxgl.Map, options: { [key: string]: string[] }) => {
 
    map.addSource('density-source', {
        type: 'geojson',
        data: generateGeoJSONFromOptions(options), 
      });

    map.addLayer({
      id: 'density-layer',
      type: 'heatmap',
      source: 'density-source',
      paint: {
        'heatmap-intensity': 1,
        'heatmap-color': [
          'interpolate',
          ['linear'],
          ['heatmap-density'],
          0,
          'blue',
          0.5,
          'lime',
          1,
          'red',
        ],
      },
    });
  };

  const generateGeoJSONFromOptions = (
    options: { [key: string]: string[] }
  ): FeatureCollection<Point, { questionId: string; value: string }> => {
    const features: Feature<Point, { questionId: string; value: string }>[] =
      Object.entries(options).flatMap(([questionId, values]) =>
        values.map((value) => ({
          type: 'Feature', 
          geometry: {
            type: 'Point', 
            coordinates: [100.523186 + Math.random() * 0.1, 13.736717 + Math.random() * 0.1],
          },
          properties: { questionId, value },
        }))
      );
  
    return {
      type: 'FeatureCollection', 
      features,
    };
  };
  
  return <div id="map" style={{ height: '500px', width: '100%' }} />;
};

export default MapComponent;
