// components/Card.tsx
import React from 'react';
import Image from 'next/image';
import { StaticImageData } from 'next/image';

interface CardProps {
  title: string;
  description: string;
  imageUrl: string | StaticImageData;
  isSelected: boolean;
  onClick: () => void;
}

const Card: React.FC<CardProps> = ({ title, description, imageUrl, isSelected, onClick }) => {
  return (
    <div
      className={`border rounded-lg p-4 flex flex-col items-center transition-transform duration-200 cursor-pointer ${
        isSelected ? 'border-blue-500 bg-blue-100' : 'border-gray-300'
      }`}
      onClick={onClick}
    >
      <Image src={imageUrl} alt={title} height={100} width={200} className="mb-4 rounded" />

      <div className={`mb-2 ${isSelected ? 'text-blue-600' : 'text-gray-700'}`}>
        {title}
      </div>
      <p className="text-center text-sm text-gray-600">{description}</p>
    </div>
  );
};

export default Card;
