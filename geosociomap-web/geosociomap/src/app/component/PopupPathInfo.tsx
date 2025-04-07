// PathPopup.tsx
import React, { useState } from "react";

interface PathPopupProps {
  id: string;
  name: string;
  description: string;
  thickness: number;
  color: string;
  onSave: (
    id: string,
    name: string,
    description: string,
    color: string,
    thickness: number
  ) => void;
  onDelete: () => void;
  onClose: () => void;
}

const PathPopup: React.FC<PathPopupProps> = ({
  id,
  name,
  description,
  thickness,
  color,
  onSave,
  onDelete,
  onClose,
}) => {
  const [pathName, setpathName] = useState(name);
  const [patDescription, setpathDescription] = useState(description);
  const [pathColor, setpathColor] = useState(color); // สีเริ่มต้น
  const [paththickness, setThickness] = useState<number>(thickness); // Default thickness value

  const colors = [
    "#60a5fa", // สีฟ้า
    "#34d399", // สีเขียว
    "#facc15", // สีเหลือง
    "#f87171", // สีแดง
    "#c084fc", // สีม่วง
    "#818cf8", // สีน้ำเงิน
    "#f8fafc", // สีเทา
  ];

  const handleDelete = () => {
    onDelete();
    onClose();
  };

  const handleSave = () => {
    onSave(id, pathName, patDescription, pathColor, paththickness); // ส่งชื่อไอคอน
    onClose();
  };

  return (
    <div style={{ position: "absolute", bottom: 20, right: 20 }}>
      <div className="bg-white w-80 p-4 rounded shadow-md">
        <div className="p-2">
          <button
            onClick={onClose}
            className="absolute top-2 right-2 text-gray-600 hover:text-gray-900 text-xl w-10 h-10 flex items-center justify-center"
            aria-label="Close"
          >
            &times;
          </button>
        </div>
        <div className="grid grid-cols gap-2">
          <label className="text-sm">ชื่อเส้น</label>
          <input
            type="text"
            value={pathName}
            onChange={(e) => setpathName(e.target.value)}
            className="mb-2 p-2 border"
          />
        </div>
        <div className="flex flex-col">
          <label className="text-sm">คำอธิบาย</label>
          <input
            type="text"
            value={patDescription}
            onChange={(e) => setpathDescription(e.target.value)}
            className="mb-2 p-2 border"
          />
        </div>
        <div className="grid items-center mb-4 gap-2">
          <label className="text-sm mr-2">
            ความกว้างเส้น {paththickness}px
          </label>
          <input
            type="range"
            min="1"
            max="10"
            value={paththickness}
            onChange={(e) => setThickness(Number(e.target.value))}
            className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
          />
        </div>
        <div className="grid grid-cols-7 gap-2">
          {colors.map((color) => (
            <div
              key={color}
              onClick={() => {
                setpathColor(color);
              }}
              className={`w-8 h-8 cursor-pointer rounded-full ${
                pathColor === color ? "border-2 border-black" : ""
              }`}
              style={{ backgroundColor: color }}
            />
          ))}
        </div>
        <div className="flex justify-between pt-4 pb-2">
          <button
            onClick={handleDelete}
            className="bg-red-400 hover:bg-red-500 transition text-sm text-white w-24 px-4 py-2 rounded"
          >
            ลบ
          </button>
          <div className="flex justify-end gap-2 ">
            <button
              onClick={handleSave}
              className="bg-blue-500 hover:bg-blue-600 transition text-sm text-white px-4 w-24 py-2 rounded"
            >
              บันทึก
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PathPopup;
