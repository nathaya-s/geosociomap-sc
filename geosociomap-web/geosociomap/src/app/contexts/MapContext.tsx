// contexts/MapContext.tsx
import React, { createContext, useState, useContext, ReactNode } from 'react';

interface MapContextProps {
  points: [number, number][];
  setPoints: React.Dispatch<React.SetStateAction<[number, number][]>>;
  isAddingPoints: boolean;
  setIsAddingPoints: React.Dispatch<React.SetStateAction<boolean>>;
}

const MapContext = createContext<MapContextProps | undefined>(undefined);

export const MapProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [points, setPoints] = useState<[number, number][]>([]);
  const [isAddingPoints, setIsAddingPoints] = useState(false);

  return (
    <MapContext.Provider value={{ points, setPoints, isAddingPoints, setIsAddingPoints }}>
      {children}
    </MapContext.Provider>
  );
};

export const useMapContext = () => {
  const context = useContext(MapContext);
  if (!context) {
    throw new Error('useMapContext must be used within a MapProvider');
  }
  return context;
};
