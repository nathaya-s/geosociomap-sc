import React, { useEffect, useState } from "react";
import { Question } from "../types/form";
import { Cancel } from "@mui/icons-material";

interface BuildingPopupProps {
  buildingName?: string;
  id: string;
  questions?: Question[];
  coordinates: number[] | number[][] | number[][][];
  onClose: () => void;
  onSaveAnswers: (
    id: string,
    answers: Record<string, string | number | string[]>,
    coordinates: number[] | number[][] | number[][][]
  ) => void;
  existingAnswers: { [key: string]: string | number | string[] };
}

const BuildingPopup: React.FC<BuildingPopupProps> = ({
  buildingName,
  questions,
  coordinates,
  id,
  onClose,
  onSaveAnswers,
  existingAnswers,
}) => {
  const [localAnswers, setLocalAnswers] = useState<
    Record<string, string | number | string[]>
  >({});

  useEffect(() => {
    setLocalAnswers(existingAnswers);
  }, [existingAnswers]);

  if (!buildingName) return null;

  const handleAnswerChange = (questionId: string, value: string | number) => {
    setLocalAnswers((prevAnswers) => ({
      ...prevAnswers,
      [questionId]: value, 
    }));
  };

  const handleSubmit = () => {
    console.log("localAnswers", localAnswers); 
    onSaveAnswers(id, localAnswers, coordinates);
    onClose(); 
  };

  return (
    <div className="fixed bottom-4 right-4 bg-white shadow-lg rounded-md p-4 max-w-96 max-h-96 overflow-x-hidden overflow-y-scroll">
      <button
        onClick={onClose}
        className="absolute top-2 right-2 text-gray-500 hover:text-gray-800"
      >
        <Cancel></Cancel>
      </button>
      <div className="flex flex-col ">
        <h2 className="text-lg font-bold text-blue-500 py-2">แบบฟอร์ม</h2>

        <div className="flex flex-col gap-2 bg-stone-100 p-2 rounded">
          {questions?.map((question) => (
            <div className="flex flex-col gap-2" key={question.id}>
              <div>
                <div className="flex justify-between items-center">
                  <div className="flex flex-col w-full">
                    <div className="w-full h-6 rounded text-sm">
                      {question.label}
                    </div>
                    {question.type === "text" && (
                      <div className="flex w-full">
                        <input
                          className="w-full h-10 rounded text-sm px-2"
                          placeholder={question.label}
                          value={localAnswers[question.id] ?? ""}
                          onChange={(e) =>
                            handleAnswerChange(question.id, e.target.value)
                          }
                          type="text"
                        />
                      </div>
                    )}

                    {question.type === "number" && (
                      <div className="flex w-full">
                        <input
                          type="number"
                          //   value={question.answer || ""}
                          value={localAnswers[question.id] || ""}
                          onChange={(e) => {
                            const value = e.target.value;
                            if (/^\d*\.?\d*$/.test(value)) {
                              handleAnswerChange(
                                question.id,
                                parseFloat(e.target.value) || 0
                              );
                            }
                          }}
                          className="w-full h-10 rounded text-sm border bg-white p-1"
                          placeholder={question.label} 
                        />
                      </div>
                    )}
                    {question.type === "multiple_choice" && (
                      <div className="bg-white rounded p-4 text-sm gap-1 flex flex-col">
                        {question.showOnMap ? (
                          <div className="flex gap-2 p-1 content-center text-xs text-blue-500 justify-end items-center">
                            <label>แสดงสีในแผนที่</label>
                          </div>
                        ) : (
                          <></>
                        )}
                        {question.options?.map((option) => (
                          <div
                            key={option.value}
                            className="flex items-center gap-x-2"
                          >
                            <label className="flex items-center gap-x-2 w-full">
                              <input
                                type="radio"
                                name={question.id}
                                value={option.value}
                                onChange={() =>
                                  handleAnswerChange(question.id, option.value)
                                }
                                checked={
                                  localAnswers[question.id] === option.value
                                }
                                className="mr-2"
                              />

                              <div className="  p-1 w-full">{option.label}</div>
                            </label>
                            {question.showOnMap && (
                              <div className="w-6 flex justify-center">
                                <div>
                                  <div
                                    style={{
                                      backgroundColor:
                                        option.color || "transparent",
                                    }}
                                    className="w-5 h-5 border rounded-full mt-2 cursor-pointer"
                                  ></div>
                                </div>
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    )}
                    {question.type === "checkbox" && (
                      <div className="bg-white rounded p-4 text-sm gap-1 flex flex-col">
                        {question.showOnMap && (
                          <div className="flex gap-2 p-1 content-center text-xs text-blue-500 justify-end items-center">
                            <label>แสดงสีในแผนที่</label>
                          </div>
                        )}
                        {question.options?.map((option) => (
                          <div
                            key={option.value}
                            className="flex items-center gap-x-2"
                          >
                            <label className="flex items-center gap-x-2 w-full">
                              <input
                                type="checkbox"
                                name={question.id}
                                value={option.value}
                                className="mr-2"
                                checked={
                                  Array.isArray(localAnswers?.[question.id])
                                    ? (localAnswers[question.id] as string[]).includes(option.value) 
                                    : localAnswers?.[question.id] === option.value || false 
                                }
                                
                                
                                onChange={(event) => {
                                  const { value, checked } = event.target;

                                  setLocalAnswers((prevAnswers) => {
                                    const updatedAnswers = { ...prevAnswers };

                                    const currentAnswers =
                                      updatedAnswers[question.id] || [];

                                    if (checked) {
                                      if (Array.isArray(currentAnswers)) {
                                        if (!currentAnswers.includes(value)) {
                                          updatedAnswers[question.id] = [
                                            ...currentAnswers,
                                            value,
                                          ];
                                        }
                                      } else {
                                        updatedAnswers[question.id] = value; 
                                      }
                                    } else {
                                      if (Array.isArray(currentAnswers)) {
                                        updatedAnswers[question.id] =
                                          currentAnswers.filter(
                                            (answer) => answer !== value
                                          );
                                      }
                                    }

                                    console.log(
                                      "Updated answers:",
                                      updatedAnswers
                                    ); 
                                    return updatedAnswers;
                                  });
                                }}
                              />

                              <div className="border bg-stone-100 rounded p-1 w-full">
                                {option.label}
                              </div>
                            </label>

                            {question.showOnMap && (
                              <div className="w-6 flex justify-center">
                                <div>
                                
                                  <div
                                    style={{
                                      backgroundColor:
                                        option.color || "transparent",
                                    }}
                                    className="w-5 h-5 border rounded-full mt-2 cursor-pointer"
                                  />
                                </div>
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          ))}
          <button
            className="bg-blue-400 hover:bg-blue-500 text-white transition rounded p-2"
            onClick={handleSubmit}
          >
            บันทึก
          </button>
        </div>
      </div>
    </div>
  );
};

export default BuildingPopup;
