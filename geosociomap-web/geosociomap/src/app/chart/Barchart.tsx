import React from "react";

interface BarChartProps {
  data: Record<string, number>;
}

const BarChart: React.FC<BarChartProps> = ({ data }) => {
  const labels = Object.keys(data);
  const values = Object.values(data);

  // Find the maximum value for scaling the bar height
  const maxValue = Math.max(...values, 0);

  return (
    <div className="flex py-4">
      <div className="relative flex justify-between items-end w-auto space-x-4 border-gray-300 rounded-lg p-4 shadow-lg h-[150px]">
        {labels.map((label, index) => {
          const value = values[index];
          const barHeight = maxValue > 0 ? (value / maxValue) * 75 : 0; // Scale bar height

          return (
            <div
              key={label}
              className="relative flex flex-col items-center"
              style={{ height: "100%" }}
            >
              {/* Container for bar */}
              <div className="relative w-8 h-[100px] flex items-end">
                {/* Bar */}
                <div
                  className="w-full bg-blue-600 rounded-md transition-all duration-300 ease-in-out"
                  style={{
                    height: `${barHeight}px`, // Dynamically scale bar height
                  }}
                />
              </div>

              {/* Value above the bar */}
              <span className="absolute -top-6 text-xs text-center w-full">
                {value}
              </span>

              {/* Label below the bar */}
              <div className="mt-2 text-xs text-center truncate w-16 relative group">
                <span>{label}</span>

                {/* Tooltip */}
                <div className="absolute hidden group-hover:block bg-black text-white text-xs p-1 rounded-md whitespace-nowrap z-10">
                  {label}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default BarChart;
