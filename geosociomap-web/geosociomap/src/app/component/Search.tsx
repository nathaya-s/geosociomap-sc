import React, { useState, useEffect } from "react";
import axios from "axios";
import { Sarabun } from "next/font/google";

interface SearchProps {
  onSearchResult: (lng: number, lat: number) => void;
}

const sarabun = Sarabun({
  weight: ["400", "500", "600", "700"],
  subsets: ["thai", "latin"],
  display: "swap",
});

interface Feature {
  center: [number, number]; 
  // context: Array<Object>;     
  geometry: {
    type: string;             
    coordinates: [number, number];  
  };
  id: string;                
  place_name: string;         
  place_type: string[];     
  properties: {
    accuracy: string;      
    mapbox_id: string;       
  };
  relevance: number;         
  text: string;               
  type: string;              
}


const Search: React.FC<SearchProps> = ({ onSearchResult }) => {
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<Feature[]>([]);

  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      if (searchQuery.trim()) {
        performSearch(searchQuery);
      } else {
        setSearchResults([]);
      }
    }, 500);

    return () => clearTimeout(delayDebounceFn);
  }, [searchQuery]);

  const performSearch = async (query: string) => {
    try {
      const response = await axios.get(
        `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(
          query
        )}.json?access_token=${process.env.NEXT_PUBLIC_MAPBOX_ACCESS_TOKEN}`
      );
      console.log(response.data.features);
      setSearchResults(response.data.features);
    } catch (error) {
      console.error("Error fetching geocoding data:", error);
    }
  };

  const handleSelectResult = (lng: number, lat: number) => {
    onSearchResult(lng, lat);
    setSearchResults([]); 
    setSearchQuery("");  
  };

  return (
    <div
      className={`absolute top-5 left-3/4 text-sm bg-white  rounded-2xl ${sarabun.className}`}
    >
      <input
        type="text"
        value={searchQuery}
        onChange={(e) => setSearchQuery(e.target.value)}
        placeholder="ค้นหา"
        className="p-2 border rounded-xl w-64 opacity-90 outline-none border border-neutral-200 rounded-lg"
      />

      {searchResults.length > 0 && (
        <ul className="rounded-xl">
          {searchResults.map((result, index) => (
            <li
              key={index}
              onClick={() =>
                handleSelectResult(result.geometry.coordinates[0],  result.geometry.coordinates[1])
              }
              className="cursor-pointer rounded-xl p-2 bg-white hover:bg-stone-100 max-w-64"
            >
              {result.place_name}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
};

export default Search;
