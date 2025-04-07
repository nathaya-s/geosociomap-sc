import React, { useState } from "react";
// import { XMarkIcon } from "@heroicons/react/24/solid";
import CancelIcon from '@mui/icons-material/Cancel';

interface EditPopupProps {
  relationshipId: string;
  initialDescription: string;
  initialType: "solid" | "double" | "dotted" | "zigzag" |  "dashed";
  onSave: (
    description: string,
    type: "solid" | "double" | "dotted" | "zigzag" |  "dashed"
  ) => void;
  onCancel: () => void;
  onDelete: (relationshipId: string, description: string, type: "solid" | "double" | "dotted" | "zigzag" | "dashed") => void;
}

const EditPopup: React.FC<EditPopupProps> = ({
  relationshipId,
  initialDescription,
  initialType,
  onSave,
  onCancel,
  onDelete,
}) => {
  const [description, setDescription] = useState(initialDescription);
  const [type, setType] = useState(initialType);

  const handleSave = () => {
    onSave(description, type);
  };

  const handleDelete = () => {
    onDelete(relationshipId, description, type);
  };

  const lineTypes: Array<"solid" | "double" | "dotted" | "zigzag" |  "dashed"> = [
    "solid",
    "dashed",
    "double",
    "zigzag",
  ];

  return (
    <div className="absolute bottom-5 right-5 bg-white p-5 rounded-lg shadow-lg w-80 z-50">
      {/* Cancel Button */}
      <button
        onClick={onCancel}
        className="absolute top-2 right-2 text-gray-500 hover:text-gray-800"
      >
        <CancelIcon className="h-5 w-5" />
      </button>

      <h3 className="text-lg font-semibold mb-3">แก้ไข</h3>

      {/* Description Input */}
      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Description:
        </label>  
        <input
          type="text"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring focus:ring-blue-200 focus:outline-none"
        />
      </div>

      {/* Line Type Buttons */}
      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 mb-2">
          ประเภทเส้น
        </label>
        <div className="flex gap-0.5 bg-gray-200 rounded-lg p-0.5">
          {lineTypes.map((lineType) => (
            <button
              key={lineType}
              onClick={() => setType(lineType)}
              className={`w-[25%] px-3 py-1 rounded text-sm font-medium ${
                type === lineType
                  ? "bg-blue-500 text-white"
                  : "bg-gray-200 text-gray-700 hover:bg-gray-300"
              }`}
            >
              {lineType}
            </button>
          ))}
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex justify-between mt-4">
        <button
          onClick={handleSave}
          className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
        >
          Save
        </button>
        <button
          onClick={handleDelete}
          className="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600"
        >
          Delete
        </button>
      </div>
    </div>
  );
};

export default EditPopup;
