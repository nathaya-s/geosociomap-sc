import React, { useEffect } from "react";

interface ColorPickerProps {
  colors: string[];
  onSelectColor: (color: string) => void; 
  onClose: () => void; 
}

const ColorPicker: React.FC<ColorPickerProps> = ({
  colors,
  onSelectColor,
  onClose,
}) => {
  const handleClickOutside = (event: MouseEvent) => {
    const target = event.target as HTMLElement;
    if (target.closest(".color-picker")) return; 
    onClose(); 
  };

  useEffect(() => {
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [handleClickOutside]); 
  

  return (
    <div className="color-picker top-28 right-1 absolute bg-white p-1 w-20 rounded shadow-lg">
      <div className="grid grid-cols-2 gap-1 ">
        {colors.map((color) => (
          <div
            key={color}
            onClick={() => onSelectColor(color)}
            className="w-8 h-8 rounded-full cursor-pointer"
            style={{ backgroundColor: color }}
          />
        ))}
      </div>
    </div>
  );
};

export default ColorPicker;
