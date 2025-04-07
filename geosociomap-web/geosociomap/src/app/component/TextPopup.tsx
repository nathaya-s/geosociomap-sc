import React, { useState } from "react";

interface TextPopupProps {
  coordinates: [number, number];
  description: string;
  handleSave: (newDescription: string) => void;
  closePopup: () => void;
}

const TextPopup: React.FC<TextPopupProps> = ({
//   coordinates,
  description,
  handleSave,
  closePopup,
}) => {
  const [inputText, setInputText] = useState(description);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value; 
    setInputText(value);
  };

  const handleSaveClick = () => {
    handleSave(inputText); 
    closePopup(); 
  };

  return (
    <div className="fixed bottom-4 right-4 bg-white shadow-lg rounded-md p-4 w-80 max-w-80 max-h-96 overflow-y-auto z-50">
      <h4 className="text-xl font-semibold mb-2">เพิ่มข้อความ</h4>
      <input
        type="text"
        value={inputText}
        onChange={handleInputChange}
        className="w-full p-2 border rounded-md mb-4"
        placeholder="เพิ่มข้อความ"
      />
      <div className="flex justify-between gap-2">
        <button
          onClick={closePopup}
          className="w-1/2 py-2 px-4 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-500 focus:outline-none focus:ring-2 focus:ring-gray-300"
        >
          ยกเลิก
        </button>

        <button
          onClick={handleSaveClick}
          className="w-1/2 py-2 px-4 bg-blue-500 text-white rounded-md hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-blue-400"
        >
          บันทึก
        </button>
      </div>
    </div>
  );
};

export default TextPopup;
