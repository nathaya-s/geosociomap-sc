import React, { useState } from 'react';

type FormType =
  | "personal_info"
  | "community_issues"
  | "financial_info"
  | "utilities_info"
  | "tourism"
  | "health"
  | "custom";

interface Option {
  value: string;
  label: string;
}

interface CustomDropdownProps {
  options: Option[];
  label: string;
  selectedValue: string; 
  onSelect: (value: FormType) => void; 
}

const CustomDropdown: React.FC<CustomDropdownProps> = ({
  options,
  label,
  selectedValue,
  onSelect,
}) => {
  const [isOpen, setIsOpen] = useState(false);

  const toggleDropdown = () => {
    setIsOpen(!isOpen);
  };

  const handleOptionSelect = (value: string) => {
    onSelect(value as FormType); 
    setIsOpen(false); 
  };

  const selectedLabel = options.find(option => option.value === selectedValue)?.label || 'เลือกแบบฟอร์ม';

  return (
    <div className="relative">
      <label className="block text-sm font-medium text-gray-700 z-50">
        {label}
      </label>
      <div className="border border-gray-300 rounded-md">
        <div
          className="flex justify-between items-center p-2 cursor-pointer"
          onClick={toggleDropdown}
        >
          <span>{selectedLabel}</span>
          <span className="text-gray-500">▼</span>
        </div>
        {isOpen && (
          <ul className="absolute bg-white border border-gray-300 rounded-md mt-1 w-full z-50">
            {options.map((option) => (
              <li
                key={option.value}
                className="p-2 hover:bg-gray-100 cursor-pointer"
                onClick={() => handleOptionSelect(option.value)}
              >
                {option.label} 
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
};

export default CustomDropdown;
