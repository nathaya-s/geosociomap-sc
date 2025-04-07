import React, { useState } from 'react';

const PopupPathComponent: React.FC<{
  title: string;
  description: string;
  lng: number;
  lat: number;
  color: string;
  thickness: number; 
  iconName: string;
  onClose: () => void;
  onDelete: () => void;
  onSave: (
    title: string,
    description: string,
    color: string,
    thickness: number, 
    iconName: string
  ) => void;
}> = ({
  title,
  description,
  // lng,
  // lat,
  color,
  thickness, 
  iconName,
  onClose,
  onSave,
  onDelete,
}) => {
  const [markerTitle, setMarkerTitle] = useState(title);
  const [markerDescription, setMarkerDescription] = useState(description);
  const [markerColor, setMarkerColor] = useState(color);
  const [markerThickness, setMarkerThickness] = useState(thickness);

  // const colors = [
  //   "#60a5fa", // สีฟ้า
  //   "#34d399", // สีเขียว
  //   "#facc15", // สีเหลือง
  //   "#f87171", // สีแดง
  //   "#c084fc", // สีม่วง
  //   "#818cf8", // สีน้ำเงิน
  //   "#a8a29e", // สีเทา
  // ];

  return (
    <div className="popup-container">
      <h3>Edit Path</h3>
      <div>
        <label>Title:</label>
        <input 
          type="text" 
          value={markerTitle} 
          onChange={(e) => setMarkerTitle(e.target.value)} 
        />
      </div>
      <div>
        <label>Description:</label>
        <textarea 
          value={markerDescription} 
          onChange={(e) => setMarkerDescription(e.target.value)} 
        />
      </div>
      <div>
        <label>Color:</label>
        <input 
          type="color" 
          value={markerColor} 
          onChange={(e) => setMarkerColor(e.target.value)} 
        />
      </div>
      <div>
        <label>Thickness:</label>
        <input 
          type="number" 
          min="1" 
          value={markerThickness} 
          onChange={(e) => setMarkerThickness(Number(e.target.value))} 
        />
      </div>
      <div>
        <button onClick={() => onSave(markerTitle, markerDescription, markerColor, markerThickness, iconName)}>
          Save
        </button>
        <button onClick={onDelete}>Delete</button>
        <button onClick={onClose}>Close</button>
      </div>
    </div>
  );
};

export default PopupPathComponent;
