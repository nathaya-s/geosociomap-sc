import React, { useState } from 'react';

interface MarkerProps {
  name: string;
  description: string;
  position: [number, number];
}

const PopupMarkerComponent: React.FC<MarkerProps> = ({ name, description, position }) => {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <div
      className="relative"
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      style={{
        position: 'absolute',
        left: `${position[1]}px`, 
        top: `${position[0]}px`, 
      }}
    >
      <div className="bg-blue-500 w-2 h-2 rounded-full"></div>
      
      {/* Tooltip */}
      {isHovered && (
        <div className="absolute bg-gray-700 text-white text-sm p-2 rounded-lg shadow-md z-10">
          <div className="font-bold">{name}</div>
          <div>{description}</div>
        </div>
      )}
    </div>
  );
};

export default PopupMarkerComponent;
