// components/ProjectSidebar.tsx
import React, { useState, useEffect } from "react";
// import Image from "next/image";
import LayersIcon from "@mui/icons-material/Layers";
// import FunctionsIcon from "@mui/icons-material/Functions";
import MapIcon from "@mui/icons-material/Map";
import PercentIcon from "@mui/icons-material/Percent";
import VisibilityIcon from "@mui/icons-material/Visibility";
import LibraryAddIcon from "@mui/icons-material/LibraryAdd";
import LockIcon from "@mui/icons-material/Lock";
import LocalFloristIcon from "@mui/icons-material/LocalFlorist";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import VisibilityOffIcon from "@mui/icons-material/VisibilityOff";
import TimelineIcon from "@mui/icons-material/Timeline";
// import { SvgIconProps } from "@mui/material/SvgIcon";
import AddPhotoAlternateIcon from "@mui/icons-material/AddPhotoAlternate";
import DeleteIcon from "@mui/icons-material/Delete";
import HighlightOffIcon from "@mui/icons-material/HighlightOff";
import ArrowDropUpIcon from "@mui/icons-material/ArrowDropUp";
import ArrowDropDownIcon from "@mui/icons-material/ArrowDropDown";
import AddIcon from "@mui/icons-material/Add";
import { v4 as uuidv4 } from "uuid";
import { Layer } from "../types/layer";
import {
  // NoteItem,
  // MainNote,
  PositionNote,
  // SubNote,
  NoteSequence,
  Attachment,
} from "../types/note";
// type IconComponent = React.ComponentType<SvgIconProps>;

import {
  DragDropContext,
  // Droppable,
  Draggable,
  DropResult,
} from "react-beautiful-dnd";
// import { StaticImageData } from "next/image";

import { Sarabun } from "next/font/google";
import { StrictModeDroppable } from "./StrictModeDroppable";
import { Divider } from "@mui/material";
import { LayerData, Question, QuestionType } from "../types/form";
import BarChart from "../chart/Barchart";
// import MapComponent from "../map/MapComponent";
import { useAuth } from "../hooks/useAuth";
import DashboardCustomizeOutlined from "@mui/icons-material/DashboardCustomizeOutlined";
import Delete from "@mui/icons-material/Delete";
// import RectangleOutlined from "@mui/icons-material/RectangleOutlined";
// import Add from "@mui/icons-material/Add";
// import ArrowDownward from "@mui/icons-material/ArrowDownward";
import ColorPicker from "./ColorPicker";
import FormatListBulleted from "@mui/icons-material/FormatListBulleted";
import People from "@mui/icons-material/People";
import { Stat } from "../types/stat";
import { TextDecrease, TextIncrease } from "@mui/icons-material";

const sarabun = Sarabun({
  weight: ["400", "500", "600", "700"],
  subsets: ["thai", "latin"],
  display: "swap",
});

interface ProjectSidebarProps {
  onAddClick: () => void;
  isModalOpen: boolean;
  layers: Layer[];
  projectId: string | null;
  setLayers: (layers: Layer[]) => void;
  selectedButton: string;
  selectedLayer: Layer | NoteSequence | null;
  setLayertype: (value: string | null) => void;
  Layertype: string | null;
  noteData: NoteSequence | null;
  setNoteData: React.Dispatch<React.SetStateAction<NoteSequence | null>>;
  setSelectedButton: (button: string) => void; 
  setSelectedLayer: (layer: Layer | NoteSequence | null) => void; 
  selectedOptions: { [key: string]: string[] };
  setSelectedOptions: React.Dispatch<
    React.SetStateAction<{ [key: string]: string[] }>
  >;
  selectedLayerData: { data: LayerData[]; layerId: string } | null;
  // layerStats: any[];
  // setLayerStats: React.Dispatch<React.SetStateAction<any[]>>;
  selectedFormLayer: string;
  setSelectedFormLayer: React.Dispatch<React.SetStateAction<string>>; 
  isCreatingBuilding: boolean;
  setIsCreatingBuilding: React.Dispatch<React.SetStateAction<boolean>>;
  isDeletingBuilding: boolean;
  setIsDeletingBuilding: React.Dispatch<React.SetStateAction<boolean>>;
  selectedMode: "Add" | "Delete" | "Text" | "DeleteText" | null; 
  setSelectedMode: React.Dispatch<
    React.SetStateAction<"Add" | "Delete" | "Text" | "DeleteText" | null>
  >;
  isFetching: boolean;
  setIsFetching: React.Dispatch<React.SetStateAction<boolean>>;
}

const ProjectSidebar: React.FC<ProjectSidebarProps> = ({
  onAddClick,
  isModalOpen,
  layers,
  projectId,
  setLayers,
  selectedButton,
  setSelectedButton,
  setSelectedLayer,
  selectedLayer,
  setLayertype,
  Layertype,
  noteData,
  setNoteData,
  selectedOptions,
  setSelectedOptions,
  selectedLayerData,
  // layerStats,
  // setLayerStats,
  setSelectedFormLayer,
  selectedFormLayer,
  setIsCreatingBuilding,
  isCreatingBuilding,
  // isDeletingBuilding,
  setIsDeletingBuilding,
  selectedMode,
  setSelectedMode,
  // isFetching,
  // setIsFetching,
}) => {
  const [activeItem, setActiveItem] = useState("layers");
  const [layerList, setLayerList] = useState<Layer[]>([]);
  const { user } = useAuth();

  //   const [selectedLayer, setSelectedLayer] = useState<Layer | null>(null);
  // const baseMapLayer = "แผนที่ฐาน";

  const toggleVisibility = (id: string) => {
    if (layers.length < 1) {
      console.log("Cannot toggle visibility: Not enough layers.");
      return; 
    }
    const updatedLayers = layers.map((layer) =>
      layer.id === id ? { ...layer, visible: !layer.visible } : layer
    );
    setLayers(updatedLayers);
    setLayerList(updatedLayers);
  };

  const handleItemClick = (item: string) => {
    if (!isModalOpen) {
      setActiveItem(item);
    }

    if (item == "statistics") {
      setSelectedLayer(null);
      setSelectedMode(null);
      setIsCreatingBuilding(false);
    }

    if (item == "layers") {
      setSelectedFormLayer("");
      setSelectedMode(null);
      setIsCreatingBuilding(false);
    }
  };

  useEffect(() => {
    if (!Array.isArray(layers) || layers.length < 1) {
      console.warn(
        "Cannot update layer list: layers is not an array or has no items."
      );
      return;
    }

    setLayerList((prevLayerList) => {
    
      const previousLayers = Array.isArray(prevLayerList) ? prevLayerList : [];

     
      return layers.map((newLayer) => {
        const existingLayer = previousLayers.find(
          (prevLayer) => prevLayer.id === newLayer.id
        );
        return existingLayer
          ? { ...newLayer, visible: existingLayer.visible } 
          : newLayer;
      });
    });
  }, [layers]);

  useEffect(() => {
    if (Array.isArray(layerList)) {
   
      const currentLayer = layerList.find(
        (layer) => layer.id === selectedLayer?.id
      );

      if (currentLayer) {
        setSelectedLayer(currentLayer);
      }
    } else {
      console.error("layerList is not an array:", layerList); 
    }
  }, [layerList, selectedLayer?.id, setSelectedLayer]);

  useEffect(() => {
    console.log("layerList", layerList);
  }, [layerList]);

  const onDragEnd = (result: DropResult) => {
    if (!result.destination) return; 
    const { source, destination } = result;

    if (destination.index >= layerList.length) return;

    const updatedLayerList = Array.from(layerList);
    const [movedLayer] = updatedLayerList.splice(source.index, 1);
    updatedLayerList.splice(destination.index, 0, movedLayer); 

    setLayerList(updatedLayerList);
    setLayers(updatedLayerList);

    console.log("Updated Layer List:", updatedLayerList);
  };
  useEffect(() => {
    setLayerList(layers); 
  }, [layers]);

  const [mainNoteText, setMainNoteText] = useState(noteData?.note);
  // const [mainNoteImages, setMainNoteImages] = useState<string[]>([]);

  const [noteTexts, setNoteTexts] = useState<{ [key: string]: string }>({});
  const [positionImages, setPositionImages] = useState<{
    [key: string]: string[];
  }>({});
  useEffect(() => {
    if (noteData?.note !== mainNoteText) {
      setMainNoteText(noteData?.note || "");
    }
  }, [noteData]);

  const handleModeChange = (mode: "Add" | "Delete" | "Text" | "DeleteText") => {
    setSelectedMode(mode);
    if (mode === "Add") {
      setIsCreatingBuilding(true);
      setIsDeletingBuilding(false);
    } else if (mode === "Delete") {
      setIsCreatingBuilding(true);
      setIsDeletingBuilding(true);
    }
    else if (mode === "Text") {
      setIsCreatingBuilding(true);
      setIsDeletingBuilding(true);
    }
    else if (mode === "DeleteText") {
      setIsCreatingBuilding(true);
      setIsDeletingBuilding(true);
    }
  };

  useEffect(() => {
    if (noteData && noteData.items) {
      const initialNotes = noteData.items.reduce((acc, item) => {
        if (item.type === "position" && item.id) {
          acc[item.id] = item.note || ""; 
        }
        return acc;
      }, {} as { [key: string]: string });

      setNoteTexts(initialNotes);
    }
  }, [noteData]);

  useEffect(() => {}, [positionImages]);

  // useEffect(() => {

  // }, [mainNoteImages]);

  const handleImageUpload = async (
    event: React.ChangeEvent<HTMLInputElement>,
    positionId: string
  ) => {
    const file = event.target.files?.[0];
    if (file && selectedLayer) {
      const attachment: Attachment = {
        name: file.name,
        type: file.type,
        size: file.size,
        lastModified: file.lastModified,
        url: URL.createObjectURL(file),
      };

   
      const formData = new FormData();
      formData.append("file", file);

      try {
        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
        const response = await fetch(
         `${API_BASE_URL}/upload`,
          {
            method: "POST",
            body: formData,
          }
        );

        if (response.ok) {
          const result = await response.json();
          const serverFileUrl = result.fileUrl; 

          setPositionImages((prevImages) => {
            const updatedImages = {
              ...prevImages,
              [positionId]: [...(prevImages[positionId] || []), serverFileUrl], 
            };

            if ("items" in selectedLayer) {
              const updatedItems = selectedLayer.items.map((note) => {
                if (note.type === "position" && note.id === positionId) {
                  return {
                    ...note,
                    attachments: [
                      ...note.attachments,
                      { ...attachment, url: serverFileUrl }, 
                    ],
                  };
                }
                return note;
              });

              const updatedLayer: NoteSequence = {
                ...selectedLayer,
                items: updatedItems,
              };

              setSelectedLayer(updatedLayer);
              setNoteData(updatedLayer);
            }

            return updatedImages;
          });
        } else {
          throw new Error("File upload failed");
        }
      } catch (error) {
        console.error("Error uploading file:", error);
      }
    }
  };

  //   const [noteSequence, setNoteSequence] = useState<NoteSequence>(selectedLayer);

  const handleMainNoteTextChange = (
    e: React.ChangeEvent<HTMLTextAreaElement>
  ) => {
    const newDescription = e.target.value;
    setMainNoteText(newDescription);
    if (selectedLayer && "items" in selectedLayer) {
      const updatedLayer = { ...selectedLayer, note: newDescription };
      setSelectedLayer(updatedLayer); 
      setNoteData(updatedLayer); 
      console.log("Updated noteData:", updatedLayer);
    }
  };

  const handleMainNoteImageUpload = async (
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    const file = e.target.files?.[0];

    if (file) {
      const attachment: Attachment = {
        name: file.name,
        type: file.type,
        size: file.size,
        lastModified: file.lastModified,
        url: URL.createObjectURL(file), 
      };

      const formData = new FormData();
      formData.append("file", file);

      try {
        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
        const response = await fetch(
         `${API_BASE_URL}/upload`,
          {
            method: "POST",
            body: formData,
          }
        );

        if (response.ok) {
          const result = await response.json();
          const serverFileUrl = result.fileUrl;

          if (selectedLayer && "attachments" in selectedLayer) {
            const updatedLayer = {
              ...selectedLayer,
              attachments: [
                ...(selectedLayer.attachments || []),
                {
                  ...attachment,
                  url: serverFileUrl, 
                },
              ],
            };

            setSelectedLayer(updatedLayer); 
            setNoteData(updatedLayer); 
          }
        } else {
          throw new Error("File upload failed");
        }
      } catch (error) {
        console.error("Error uploading file:", error);
      }
    }
  };

  const handleNoteTextChange = (
    e: React.ChangeEvent<HTMLTextAreaElement>,
    id: string
  ) => {
    const newNote = e.target.value;

    setNoteTexts((prevNoteTexts) => ({
      ...prevNoteTexts,
      [id]: newNote,
    }));

    if (selectedLayer && "items" in selectedLayer) {
      const updatedItems = selectedLayer.items.map((item) =>
        item.id === id && item.type === "position"
          ? { ...item, note: newNote }
          : item
      ) as PositionNote[];

      const updatedLayer = { ...selectedLayer, items: updatedItems };

      setSelectedLayer(updatedLayer);

      setNoteData(updatedLayer);

      console.log("Updated selectedLayer:", updatedLayer);
    }
  };

  const handleImageDelete = (itemId: string, imgIndex: number) => {
    setPositionImages((prevImages) => {
      const updatedImages = { ...prevImages };

      if (!Array.isArray(updatedImages[itemId])) {
        updatedImages[itemId] = []; 
      }

      updatedImages[itemId] = updatedImages[itemId].filter(
        (_, index) => index !== imgIndex
      );
      return updatedImages;
    });

    if (selectedLayer && "items" in selectedLayer) {
      const updatedItems = selectedLayer.items.map((item) => {
        if (item.id === itemId && item.type === "position") {
          return {
            ...item,
            attachments: item.attachments.filter(
              (_, index) => index !== imgIndex
            ),
          };
        }
        return item;
      });

      setSelectedLayer({ ...selectedLayer, items: updatedItems });
      setNoteData(selectedLayer);
    }
  };

  // const handleMainNoteImageDelete = (imgIndex: number) => {
  //   setMainNoteImages((prevImages) =>
  //     prevImages.filter((_, index) => index !== imgIndex)
  //   );
  // };


  const handleMainImageDelete = (file: Attachment, imgIndex: number) => {
    if (selectedLayer && "markers" in selectedLayer) return;

    if (selectedLayer && selectedLayer.attachments) {
      const updatedAttachments = selectedLayer.attachments.filter(
        (_, index) => index !== imgIndex 
      );

      const updatedLayer = {
        ...selectedLayer,
        attachments: updatedAttachments,
      };

      setSelectedLayer(updatedLayer);

      if (noteData) {
        const updatedNoteData = {
          ...noteData,
          attachments: updatedAttachments,
        };

        setNoteData(updatedNoteData);
      }
    }
  };

  // const [isFetching, setIsFetching] = useState(false);
  const saveLayer = async (layer: NoteSequence, projectId: string) => {
    console.log("save note", layer);

    if (layer == null) {
      console.log("Note is empty, unable to save.");
      return;
    }

    const sanitizedLayer = {
      ...layer,
      attachments: await Promise.all(
        layer.attachments.map(async (file: Attachment) => {
          if (!file.url) {
            const fileUrl = await uploadFile(file); 
            return {
              name: file.name,
              type: file.type,
              size: file.size,
              lastModified: file.lastModified,
              url: fileUrl, 
            };
          }
        
          return {
            name: file.name,
            type: file.type,
            size: file.size,
            lastModified: file.lastModified,
            url: file.url,
          };
        })
      ),
      userId: user?.uid,
      updatedAt: new Date().toISOString(),
    };

    try {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      const response = await fetch(
       `${API_BASE_URL}/notes/save/${projectId}`,
        {
          method: "PUT", 
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(sanitizedLayer),
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to save note: ${response.statusText}`);
      }

      const responseData = await response.json();
      console.log("Note updated successfully:", responseData);
      return responseData;
    } catch (error) {
      console.error("Error saving note:", error);
      throw new Error("Failed to save note data to database");
    }
  };

  const uploadFile = async (file: Attachment) => {
    const formData = new FormData();

    const fileBlob = new Blob([file.url], { type: file.type });

    formData.append("file", fileBlob, file.name);
    const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL

    const response = await fetch(
     `${API_BASE_URL}/upload`,
      {
        method: "POST",
        body: formData,
      }
    );

    const result = await response.json();
    if (response.ok) {
      return result.fileUrl;
    } else {
      throw new Error("File upload failed");
    }
  };

  useEffect(() => {
    if (noteData && projectId) {
      saveLayer(noteData, projectId)
        .then((responseData) => {
          console.log("Layer saved:", responseData);
        })
        .catch((error) => {
          console.error("Error saving layer:", error);
        });
    }
  }, [noteData, projectId]);

  const toggleVisibilityNote = () => {
    if (noteData == null) {
      // setNoteData({
      //   id: "note",
      //   items: [], 
      //   note: "",
      //   imageUrls: [],
      //   attachments: [],
      //   visible: true, 
      // });
      return;
    } 

    setNoteData((prevNoteSequence) => {
      if (prevNoteSequence == null) return null;

      return {
        ...prevNoteSequence,
        visible: !prevNoteSequence.visible, 
      };
    });
  };

  useEffect(() => {
    setSelectedLayer(noteData);
  }, [noteData?.visible]);

  const handleDeletePosition = (itemId: string) => {
    console.log("Item ID to delete:", itemId);

    setNoteData((prev) => {
      if (!prev) return null; 
      const updatedItems =
        prev.items?.filter((item) => item.id !== itemId) || [];
      console.log("Updated items for noteData:", updatedItems);

      return {
        ...prev,
        items: updatedItems,
      };
    });

    if (selectedLayer && "items" in selectedLayer) {
      const updatedItems = selectedLayer.items.filter(
        (item) => item.id !== itemId
      );

      const updatedLayer: NoteSequence = {
        ...selectedLayer,
        items: updatedItems,
      };

      setSelectedLayer(updatedLayer);
    }
  };

  const [isEditing, setIsEditing] = useState(false);
  const [newTitles, setNewTitles] = useState<{ [key: string]: string }>({}); 

  const handleEditClick = async () => {
    if (isEditing) {
      const updates = layerList.map(async (layer) => {
        if (
          newTitles[layer.id] &&
          newTitles[layer.id] !== layer.title &&
          user
        ) {
          const updatedLayer = {
            ...layer,
            title: newTitles[layer.id],
            userId: user.uid,
            sharedWith: [],
            lastUpdate: new Date().toISOString(),

          };

          try {
            const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
            const response = await fetch(
             `${API_BASE_URL}/layers/update/${layer.id}`,
              {
                method: "PUT",
                headers: {
                  "Content-Type": "application/json",
                },
                body: JSON.stringify(updatedLayer),
              }
            );

            if (response.ok) {
              console.log(`Layer ${layer.id} updated successfully`);
              layer.title = newTitles[layer.id]; 
            } else {
              console.error(`Failed to update layer ${layer.id}`);
            }
          } catch (error) {
            console.error(`Error updating layer ${layer.id}:`, error);
          }
        }
      });

      await Promise.all(updates);
    }

    setIsEditing(!isEditing);
  };

  const handleTitleChange = (id: string, value: string) => {
    setNewTitles((prev) => ({
      ...prev,
      [id]: value,
    }));
  };

  const handleDeleteLayer = async (id: string) => {
    const updatedLayers = layerList.filter((layer) => layer.id !== id);
    setLayerList(updatedLayers);

    try {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      const response = await fetch(
        `${API_BASE_URL}/layers/update/${id}`,
        {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            userId: user?.uid,
            isDeleted: true,
            lastUpdate: new Date().toISOString(),
            ...updatedLayers, 
          }),
        }
      );

      const result = await response.json();
      if (response.ok) {
        console.log("Layer updated successfully:", result);
      } else {
        console.error("Failed to update layer:", result);
      }
    } catch (error) {
      console.error("Error updating layer:", error);
    }

  };

  // const [selectedFormLayer, setSelectedFormLayer] = useState<string>("");

  const handleSelectChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    console.log(event.target.value);
    console.log(event.target.value);
    console.log(event.target.value);
    console.log(event.target.value);
    console.log(event.target.value);
    console.log(event.target.value);
    setSelectedFormLayer(event.target.value);
  };

  useEffect(() => {}, [selectedFormLayer]);

  // const [layerStats, setLayerStats] = useState<any[]>([]);
  // const [loading, setLoading] = useState<boolean>(true);
  // const [error, setError] = useState<string | null>(null);

  // useEffect(() => {
  //   const fetchLayerStats = async () => {
  //     if (!layers || layers.length === 0) {
  //       console.log("No layers found. Skipping fetch.");
  //       return; 
  //     }

  //     try {
  //      
  //       const layersToFetch = layers.filter((layer) =>
  //         layer.id.startsWith("layer-form-")
  //       );

  //     
  //       for (const layer of layersToFetch) {
  //         const response = await fetch(
  //           `http://localhost:4000/layers/${layer.id}/buildings?userId=${user?.uid}` 
  //         );

  //         if (!response.ok) {
  //           console.error(`Failed to fetch data for layer ${layer.id}`);
  //           continue;
  //         }

  //         const data = await response.json();
  //         console.log(`Data for layer ${layer.id}:`, data);

  //         setLayerStats((prevStats) => [
  //           ...prevStats,
  //           { layerId: layer.id, data },
  //         ]);
  //       }

  //       setLoading(false);
  //     } catch (err) {
  //       console.error("Error fetching layer stats:", err);
  //       setLoading(false);
  //     }
  //   };

  //   fetchLayerStats();
  // }, [layers, selectedFormLayer]); // useEffect จะทำงานทุกครั้งเมื่อ layers เปลี่ยนแปลง

  function generateStatistics(
    data: LayerData[], 
    selectedLayerId: string
  ): Record<string, Stat> {
  
    if (!Array.isArray(data)) {
      console.error("Data is not an array", data);
      return {}; 
    }

 
    const filteredData = data.filter(
      (entry) => entry.layerId === selectedLayerId
    );

    if (filteredData.length === 0) {
      console.warn(`No data found for layerId: ${selectedLayerId}`);
      return {};
    }

  
    const selectedLayer = layers.find((layer) => layer.id === selectedLayerId);
    if (!selectedLayer) {
      console.error("Layer not found");
      return {};
    }

    const questions = selectedLayer.questions;
    const statistics: Record<string, Stat> = {};

    questions.forEach((question) => {
      const { id, type, label, options } = question;
      const relevantAnswers = filteredData
        .map((entry) => entry.answers[id]) 
        .filter(Boolean); 

      switch (type) {
        case "multiple_choice":
          if (options) {
            const counts = options.reduce((acc, option) => {
              acc[option.label] = relevantAnswers.filter(
                (answer) => answer === option.value
              ).length;
              return acc;
            }, {} as Record<string, number>);

            if (Object.keys(counts).length > 0) {
              statistics[id] = { label, type, data: counts };
            }
          }
          break;

        case "number":
          const numericAnswers = relevantAnswers
            .map(Number)
            .filter((num) => !isNaN(num));
          const mean =
            numericAnswers.reduce((sum, val) => sum + val, 0) /
              numericAnswers.length || 0;
          const median = getMedian(numericAnswers); 
          const max = Math.max(...numericAnswers);
          const min = Math.min(...numericAnswers);

          statistics[id] = { label, type, data: { mean, median, max, min } };
          break;

      }
    });

    if (Object.keys(statistics).length === 0) {
      console.warn("No statistics generated");
      return {}; 
    }

    return statistics;
  }

  function getMedian(numbers: number[]): number {
    const sorted = [...numbers].sort((a, b) => a - b);
    const mid = Math.floor(sorted.length / 2);
    return sorted.length % 2 !== 0
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  const [selectedQuestions, setSelectedQuestions] = useState<string[]>([]);
  // const [selectedOptions, setSelectedOptions] = useState({});
  // type SelectedOptions = {
  //   [questionId: string]: string[]; 
  // };
  // const [selectedOptions, setSelectedOptions] = useState<SelectedOptions>({});

  const currentLayer = Array.isArray(layers)
    ? layers.find((layer) => layer.id === selectedFormLayer)
    : null;
  const questions = currentLayer?.questions || [];

  const handleQuestionChange = (questionId: string) => {
    setSelectedQuestions((prev) => {
      const updatedQuestions = prev.includes(questionId)
        ? prev.filter((id) => id !== questionId)
        : [...prev, questionId];

   
      // setTimeout(updateDensityLayer, 0);

      return updatedQuestions;
    });
  };

  // const handleOptionChange = (
  //   questionId: string,
  //   optionValue: string,
  //   isChecked: boolean
  // ) => {
  //   setSelectedOptions((prev) => {
  //     const options = prev[questionId] || [];
  //     if (isChecked) {
  //       return {
  //         ...prev,
  //         [questionId]: [...options, optionValue],
  //       };
  //     } else {
  //       return {
  //         ...prev,
  //         [questionId]: options.filter((value) => value !== optionValue),
  //       };
  //     }
  //   });
  // };

  // const generateDensityData = () => {
  //   const features = [];

  //   for (const questionId of selectedQuestions) {
  //     const options = selectedOptions[questionId] || [];
  //     for (const optionValue of options) {
  //    
  //       features.push({
  //         type: "Feature",
  //         geometry: {
  //           type: "Point",
  //           coordinates: [
  //             ,/* longitude */
  //             /* latitude */
  //           ],
  //         },
  //         properties: {
  //           questionId,
  //           optionValue,
  //         },
  //       });
  //     }
  //   }

  //   return {
  //     type: "FeatureCollection",
  //     features,
  //   };
  // };

  const handleOptionChange = (
    questionId: string,
    optionValue: string,
    isChecked: boolean
  ) => {
    setSelectedOptions((prev) => {
      const options = prev[questionId] || [];
      const updatedOptions = isChecked
        ? [...options, optionValue]
        : options.filter((value) => value !== optionValue);

      // setTimeout(updateDensityLayer, 0);

      return {
        ...prev,
        [questionId]: updatedOptions,
      };
    });
  };

  const toggleCreateBuilding = () => {
    setIsCreatingBuilding((prev) => !prev);
  };

  useEffect(() => {
    if (isCreatingBuilding) {
      setSelectedLayer(null);
    }
  }, [isCreatingBuilding]);

  useEffect(() => {
    if (selectedLayer !== null) {
      setIsCreatingBuilding(false);
    }
  }, [selectedLayer]);

  const [isPopupVisible, setIsPopupVisible] = useState(false);

  const handleOpenPopup = () => {
    setIsPopupVisible(true);
  };

  const handleClosePopup = () => {
    if (!selectedLayer || !layers) return;

    const foundLayer = layers.find((layer) => layer.id === selectedLayer.id);

    if (foundLayer) {
      setSelectedLayer(foundLayer);
    } else {
      console.error("ไม่พบ layer ที่ตรงกับ id");
    }
    setIsPopupVisible(false);
  };

  const handleFormConfirm = async () => {
    if (!selectedLayer || !layers) return;
    if (isLayer(selectedLayer) && selectedLayer.questions) {
      const updatedLayers = layers.map((layer) => {
        if (layer.id === selectedLayer.id) {
          return { ...selectedLayer };
        }
        return layer; 
      });

  
      setLayers(updatedLayers);
      setIsPopupVisible(false);

      try {
        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
        const response = await fetch(
         `${API_BASE_URL}/layers/update/${selectedLayer.id}`,
          {
            method: "PUT",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              userId: user?.uid, 
              lastUpdate: new Date().toISOString(),
              ...selectedLayer,
            }),
          }
        );

        const result = await response.json();
        if (response.ok) {
          console.log("Layer updated successfully:", result);
        } else {
          console.error("Failed to update layer:", result);
        }
      } catch (error) {
        console.error("Error updating layer:", error);
      }
    }
  };

  const isLayer = (layer: Layer | NoteSequence): layer is Layer => {
    return (layer as Layer).questions !== undefined;
  };

  const handleLabelChange = (questionId: string, newLabel: string) => {
    if (!selectedLayer) return;
    if (isLayer(selectedLayer) && selectedLayer.questions) {
      const updatedQuestions = selectedLayer.questions.map((question) =>
        question.id === questionId ? { ...question, label: newLabel } : question
      );

      setSelectedLayer({ ...selectedLayer, questions: updatedQuestions });
    }
  };

  const moveQuestionUp = (index: number) => {
    if (!selectedLayer || index <= 0) return;

    if (isLayer(selectedLayer) && selectedLayer.questions) {
      const updatedQuestions = [...selectedLayer.questions];
      [updatedQuestions[index - 1], updatedQuestions[index]] = [
        updatedQuestions[index],
        updatedQuestions[index - 1],
      ];

      setSelectedLayer({ ...selectedLayer, questions: updatedQuestions });
    }
  };

  const moveQuestionDown = (index: number) => {
    if (selectedLayer && isLayer(selectedLayer) && selectedLayer.questions) {
      if (!selectedLayer || index >= selectedLayer.questions.length - 1) return;

      const updatedQuestions = [...selectedLayer.questions];
      [updatedQuestions[index], updatedQuestions[index + 1]] = [
        updatedQuestions[index + 1],
        updatedQuestions[index],
      ];

      setSelectedLayer({ ...selectedLayer, questions: updatedQuestions });
    }
  };

  const handleDeleteQuestion = (questionId: string) => {
    if (!selectedLayer) return;

    if (isLayer(selectedLayer) && selectedLayer.questions) {
      const updatedQuestions = selectedLayer.questions.filter(
        (question) => question.id !== questionId
      );

      setSelectedLayer({ ...selectedLayer, questions: updatedQuestions });
    }
  };

  const handleNumberChange = (questionId: string, value: string) => {
    if (!selectedLayer) return;
    if (isLayer(selectedLayer) && selectedLayer.questions) {
      const updatedQuestions = selectedLayer.questions.map((question) =>
        question.id === questionId ? { ...question, number: value } : question
      );

      setSelectedLayer({ ...selectedLayer, questions: updatedQuestions });
    }
  };

  const handleOptionLabelChange = (
    questionId: string,
    optIndex: number,
    value: string
  ) => {
    if (!selectedLayer) return;
    if (isLayer(selectedLayer) && selectedLayer.questions) {
      const updatedQuestions = selectedLayer.questions.map((question) => {
        if (question.id === questionId) {
          const updatedOptions = question.options ? [...question.options] : [];
          updatedOptions[optIndex] = {
            ...updatedOptions[optIndex],
            label: value,
          };
          return { ...question, options: updatedOptions };
        }
        return question;
      });

      setSelectedLayer({ ...selectedLayer, questions: updatedQuestions });
    }
  };

  const handleRemoveOption = (questionId: string, optIndex: number) => {
    if (!selectedLayer) return;

    if (isLayer(selectedLayer) && selectedLayer.questions) {
      const updatedQuestions = selectedLayer.questions.map((question) => {
        if (question.id === questionId) {
          const updatedOptions = question.options
            ? question.options.filter((_, index) => index !== optIndex)
            : [];
          return { ...question, options: updatedOptions };
        }
        return question;
      });

      setSelectedLayer({ ...selectedLayer, questions: updatedQuestions });
    }
  };

  const handleAddOption = (questionId: string) => {
    if (!selectedLayer) return;
    if (isLayer(selectedLayer) && selectedLayer.questions) {
      const updatedQuestions = selectedLayer.questions.map((question) => {
        if (question.id === questionId) {
          const updatedOptions = question.options ? [...question.options] : [];
          updatedOptions.push({ value: "", label: "" });
          return { ...question, options: updatedOptions };
        }
        return question;
      });

      setSelectedLayer({ ...selectedLayer, questions: updatedQuestions });
    }
  };

  // const handleShowOnMapToggle = (questionId: string) => {
  //   if (!selectedLayer) return;

  //   if (isLayer(selectedLayer) && selectedLayer.questions) {
  //     const updatedQuestions = selectedLayer.questions.map((question) => {
  //       if (question.id === questionId) {
  //         return { ...question, showOnMap: !question.showOnMap }; 
  //       } else {
  //         return { ...question, showOnMap: false }; // Set others to false
  //       }
  //     });

  //     setSelectedLayer({ ...selectedLayer, questions: updatedQuestions });
  //   }
  // };

  const handleAddQuestion = (questionType: QuestionType) => {
    if (!selectedLayer) return;
    if (isLayer(selectedLayer) && selectedLayer.questions) {
      const newQuestion: Question = {
        id: uuidv4(), 
        label: "", 
        type: questionType,
        options:
          questionType === "multiple_choice" || questionType === "checkbox"
            ? [
                { label: "", value: "", color: "" }, 
              ]
            : undefined, 
        showMapToggle:
          questionType === "multiple_choice" || questionType === "checkbox"
            ? true
            : undefined,
        showOnMap: false,
        answer: "",
      };

      const updatedQuestions = [...selectedLayer.questions, newQuestion];

      setSelectedLayer({ ...selectedLayer, questions: updatedQuestions });
      setShowAddQuestionMenu(false);
    }
  };

  // const [optionColors, setOptionColors] = useState<{ [key: string]: string }>(
  //   {}
  // ); 
  const [showAddQuestionMenu, setShowAddQuestionMenu] = useState(false); 

  // const [selectedColor, setSelectedColor] = useState<string | null>(
  //   "transparent"
  // ); // Initialize as transparent
  const [showColorPicker, setShowColorPicker] = useState(false);
  const [activeColorOption, setActiveColorOption] = useState<{
    questionId: string;
    index: number;
  } | null>(null);

  const colors = [
    "#ef4444", // สีน้ำเงิน
    "#f97316", // สีเทา
    "#f59e0b",
    "#eab308",
    "#fde047",
    "#84cc16",
    "#4ade80",
    "#34d399",
    "#2dd4bf",
    "#22d3ee",
    "#0ea5e9",
    "#3b82f6",
    "#6366f1",
    "#8b5cf6",
    "#a855f7",
    "#d946ef",
    "#ec4899",
    "#f43f5e",
  ];

  // const resetOptionColors = () => {
  //   setOptionColors({});
  //   setSelectedColor("transparent"); 
  //   setShowColorPicker(false); 
  //   setActiveColorOption(null); 
  // };

  const openColorPicker = (questionId: string, index: number) => {
    setActiveColorOption({ questionId, index });
    setShowColorPicker(true); 
  };

  const closeColorPicker = () => {
    setShowColorPicker(false);
  };

  const handleSelectColor = (
    questionId: string,
    optionIndex: number,
    selectedColor: string
  ) => {
    if (!selectedLayer) return;
    if (isLayer(selectedLayer) && selectedLayer.questions) {
      const updatedQuestions = selectedLayer.questions.map((question) => {
        if (question.id === questionId && question.options) {
          const updatedOptions = question.options.map((option, index) =>
            index === optionIndex ? { ...option, color: selectedColor } : option
          );
          return { ...question, options: updatedOptions };
        }
        return question;
      });

      setSelectedLayer({ ...selectedLayer, questions: updatedQuestions });
      closeColorPicker(); 
    }
  };

  return (
    <div className={`flex ${sarabun.className} z-40`}>
      <div
        className={`py-4 grid grid-rows gap-1 content-start h-screen bg-blue-400 text-sm text-white`}
      >
        <div
          onClick={() => handleItemClick("layers")}
          className={`flex flex-col items-center col-span-1 p-2 ${
            activeItem === "layers"
              ? "bg-stone-100 text-blue-600"
              : "bg-blue-400 text-white hover:bg-blue-500"
          } cursor-pointer duration-300 ease-in-out transform`}
        >
          <LayersIcon />
          <p className="mt-2  text-xs">เลเยอร์</p>
        </div>

        <div
          onClick={() => handleItemClick("statistics")}
          className={`flex flex-col items-center col-span-1 p-2 
            ${
              activeItem === "statistics"
                ? "bg-stone-100 text-blue-600"
                : "bg-blue-400 text-white hover:bg-blue-500"
            } 
          cursor-pointer duration-300 ease-in-out transform`}
        >
          <PercentIcon />
          <p className=" mt-2  text-xs">สถิติ</p>
        </div>

        <div
          onClick={() => handleItemClick("density")}
          className={`flex flex-col items-center col-span-1 p-2 ${
            activeItem === "density"
              ? "bg-stone-100 text-blue-600"
              : "bg-blue-400 text-white hover:bg-blue-500"
          } cursor-pointer duration-300 ease-in-out transform`}
        >
          <MapIcon />
          <p className="mt-2 text-xs">Heatmap</p>
        </div>
      </div>

      <div className="bg-white w-64 h-screen p-3 overflow-y-auto">
        {activeItem === "layers" && (
          <div className="grid grid-rows">
            <div className="flex text-blue-500 justify-between items-center content-center mb-4">
              <div className="text-sm" onClick={() => handleEditClick()}>
                {isEditing ? "บันทึก" : "แก้ไข"}
              </div>
              <button>
                <LibraryAddIcon className="h-5" onClick={onAddClick} />
              </button>
            </div>
            <div className="gap-2 grid">
              <div
                className={`flex px-3 py-4 rounded-md justify-between items-center ${
                  isCreatingBuilding ? "bg-[#dbeafe]" : "bg-[#F4F4F4]"
                }`}
                onClick={toggleCreateBuilding}
              >
                <MapIcon className="text-blue-500" />
                <div className="text-gray-700 text-sm">แผนที่ฐาน</div>
                <LockIcon className="h-4 text-stone-400" />
              </div>
              <div
                className={`flex px-3 py-4 rounded-md justify-between items-center ${
                  "note" === Layertype ? "bg-[#dbeafe]" : "bg-[#F4F4F4]"
                }`}
                onClick={() => {
                  console.log("setSelectedLayer(noteData);");
                  setSelectedLayer(noteData);
                  setLayertype("note"); 
                }}
              >
                <MapIcon className="text-blue-500" />
                <div className="text-gray-700 text-sm">บันทึกย่อ</div>
                <div onClick={() => toggleVisibilityNote()}>
                  {noteData?.visible ? (
                    <VisibilityIcon className="h-4 text-stone-400" />
                  ) : (
                    <VisibilityOffIcon className="h-4 text-stone-400" />
                  )}
                </div>
              </div>
              <Divider />{" "}
              <DragDropContext onDragEnd={onDragEnd}>
                <StrictModeDroppable droppableId="layers">
                  {(provided) => (
                    <div
                      className="gap-2 grid"
                      {...provided.droppableProps}
                      ref={provided.innerRef}
                    >
                      {Array.isArray(layerList) && layerList.length > 0 ? (
                        layerList.map((layer, index) => (
                          <Draggable
                            key={layer.id}
                            draggableId={layer.id}
                            index={index}
                          >
                            {(provided) => (
                              <div
                                ref={provided.innerRef}
                                {...provided.draggableProps}
                                {...provided.dragHandleProps}
                                className={`flex px-3 py-4 rounded-md justify-between items-center ${
                                  selectedLayer?.id === layer.id
                                    ? "bg-[#dbeafe]"
                                    : "bg-[#F4F4F4]"
                                }`}
                                onClick={() => setSelectedLayer(layer)}
                              >
                                {layer.id.startsWith("layer-symbol-") && (
                                  <LocalFloristIcon className="text-blue-500" />
                                )}
                                {layer.id.startsWith("layer-form-") && (
                                  <FormatListBulleted className="text-blue-500" />
                                )}
                                {layer.id.startsWith("layer-relationship-") && (
                                  <People className="text-blue-500" />
                                )}

                                <div className="text-gray-700 text-sm">
                                  {isEditing ? (
                                    <input
                                      type="text"
                                      value={newTitles[layer.id] || layer.title}
                                      onChange={(e) =>
                                        handleTitleChange(
                                          layer.id,
                                          e.target.value
                                        )
                                      }
                                      // onBlur={() => handleSaveTitle(layer.id)}
                                      className="border px-1 rounded"
                                    />
                                  ) : (
                                    layer.title
                                  )}
                                </div>
                                {!isEditing ? (
                                  <div
                                    onClick={() => toggleVisibility(layer.id)}
                                  >
                                    {layer.visible ? (
                                      <VisibilityIcon className="h-4 text-stone-400" />
                                    ) : (
                                      <VisibilityOffIcon className="h-4 text-stone-400" />
                                    )}
                                  </div>
                                ) : (
                                  <div
                                    onClick={() => handleDeleteLayer(layer.id)}
                                  >
                                    <DeleteIcon className="h-4 text-stone-400" />
                                  </div>
                                )}
                              </div>
                            )}
                          </Draggable>
                        ))
                      ) : (
                        <p>No layers found</p>
                      )}
                      {provided.placeholder}
                    </div>
                  )}
                </StrictModeDroppable>
              </DragDropContext>
            </div>
          </div>
        )}
        {activeItem === "statistics" && (
          <div>
            <h3 className="text-blue-500 mb-4">สถิติ</h3>
            <select
              id="layerDropdown"
              className="w-full p-2 text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              value={selectedFormLayer}
              onChange={handleSelectChange}
            >
              <option value="" disabled>
                -- เลือก Layer --
              </option>
              {
                Array.isArray(layers) &&
                  layers
                    .filter(
                      (layer) =>
                        layer.id.startsWith("layer-form-") &&
                        layer.questions?.length > 0
                    )
                    .map((layer) => (
                      <option key={layer.id} value={layer.id}>
                        {layer.title}
                      </option>
                    ))
              }
            </select>
            {selectedFormLayer && selectedLayerData && (
              <div className="mt-4">
                {Object.entries(
                  generateStatistics(selectedLayerData.data, selectedFormLayer)
                ).map(([id, stat]) => (
                  <div key={id} className="py-2 text-sm">
                    <h5 className="text-blue-500">{stat.label}</h5>
                    {stat.type === "multiple_choice" && (
                      <BarChart data={stat.data} />
                    )}
                    {stat.type === "number" && (
                      <div className="text-sm">
                        <p>ค่าเฉลี่ย: {stat.data.mean}</p>
                        <p>ค่ามัธยฐาน: {stat.data.median}</p>
                        <p>ค่าสูงสุด: {stat.data.max}</p>
                        <p>ค่าต่ำสุด: {stat.data.min}</p>
                      </div>
                    )}
                    {stat.type === "text" && (
                      <div>
                        <p>ตัวอย่างคำตอบ:</p>
                        <ul>
                          {stat.data
                            .slice(0, 5)
                            .map((text: string, idx: number) => (
                              <li key={idx}>- {text}</li>
                            ))}
                        </ul>
                      </div>
                    )}
                    {stat.type === "checkbox" && <BarChart data={stat.data} />}
                    {/* {stat.type === "file_upload" && (
                      <p>จำนวนไฟล์ที่อัปโหลด: {stat.data}</p>
                    )} */}
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
        {activeItem === "density" && (
          <div className="gap-2 grid grid-rows ">
            <h3 className="text-blue-500 mb-4 ">Heatmap</h3>
            <div>
              <select
                id="layerDropdown"
                className="w-full p-2  text-sm border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                value={selectedFormLayer}
                onChange={handleSelectChange}
              >
                <option value="" disabled>
                  -- เลือก Layer --
                </option>
                {
                  Array.isArray(layers) &&
                    layers
                      .filter(
                        (layer) =>
                          layer.id.startsWith("layer-form-") &&
                          layer.questions?.length > 0
                      )
                      .map((layer) => (
                        <option key={layer.id} value={layer.id}>
                          {layer.title}
                        </option>
                      ))
                }
              </select>
            </div>
            {questions
              .filter(
                (question) =>
                  question.type === "multiple_choice" ||
                  question.type === "checkbox"
              )
              .map((question) => (
                <div
                  key={question.id}
                  className="p-4 bg-gray-100 rounded shadow text-sm"
                >
                  <div className="flex items-center justify-between">
                    <span className="font-medium">{question.label}</span>
                    <input
                      type="checkbox"
                      checked={selectedQuestions.includes(question.id)}
                      onChange={() => handleQuestionChange(question.id)}
                      className="form-checkbox text-blue-500"
                    />
                  </div>

                  {(question.type === "multiple_choice" ||
                    question.type === "checkbox") &&
                    question.options && (
                      <ul className="mt-2 space-y-2 pl-4">
                        {question.options.map((option) => (
                          <li
                            key={option.value}
                            className="flex items-center space-x-2"
                          >
                            <input
                              type="checkbox"
                              id={`${question.id}-${option.value}`}
                              name={question.id}
                              value={option.value}
                              checked={
                                selectedOptions[question.id]?.includes(
                                  option.value
                                ) || false
                              }
                              onChange={(e) =>
                                handleOptionChange(
                                  question.id,
                                  option.value,
                                  e.target.checked
                                )
                              }
                              className="form-checkbox text-green-500"
                            />
                            <label
                              htmlFor={`${question.id}-${option.value}`}
                              className="text-sm"
                            >
                              {option.label}
                            </label>
                          </li>
                        ))}
                      </ul>
                    )}
                </div>
              ))}
          </div>
        )}
        {selectedLayer && "items" in selectedLayer && (
          <div
            className="fixed top-4 left-[330px] w-80 shadow-lg grid gap-2 max-h-[500px] overflow-y-auto"
            style={{ zIndex: 1000 }}
          >
            <div className="bg-white p-3 text-sm rounded-md">
              <div className=" text-stone-600 text-lg mb-2">บันทึกข้อมูล</div>

              <div className="max-h-60 overflow-y-auto">
                {noteData?.items.map(
                  (item, index) =>
                    item.type === "position" && (
                      <div
                        key={item.id}
                        className="bg-gray-50 p-2 rounded-md mt-2"
                      >
                        <div className="flex gap-1 content-center items-center text-blue-500">
                          <LocationOnIcon />
                          <div>{item.latitude.toPrecision(7).toString()}</div>
                          <div>{item.longitude.toPrecision(8).toString()}</div>
                        </div>

                        <div className="grid grid-cols-3 gap-2 mt-2">
                          {item.attachments?.map((file, imgIndex) => {
                            const isImage = file.type.startsWith("image/"); 
                            return (
                              <div key={imgIndex} className="relative">
                                {isImage ? (
                                  <img
                                    src={file.url} 
                                    alt={`Uploaded ${file.name}`}
                                    className="w-full h-20 object-cover rounded-md cursor-pointer"
                                    onClick={() =>
                                      window.open(file.url, "_blank")
                                    }
                                  />
                                ) : (
                                  <div className="w-full h-20 bg-gray-200 flex items-center justify-center rounded-md text-center">
                                    {file && file.url ? (
                                      <a
                                        href={file.url}
                                        download={file.name}
                                        className="text-gray-600"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                      >
                                        {file.name}
                                      </a>
                                    ) : (
                                      <div>No valid file available</div>
                                    )}
                                  </div>
                                )}

                                <button
                                  onClick={() =>
                                    handleImageDelete(item.id, imgIndex)
                                  }
                                  className="absolute top-1 right-1 rounded-full p-1"
                                >
                                  <HighlightOffIcon className="text-white" />
                                </button>
                              </div>
                            );
                          })}
                        </div>

                        <textarea
                          value={noteTexts[item.id] || ""}
                          onChange={(e) => handleNoteTextChange(e, item.id)}
                          placeholder="เขียนบันทึกที่นี่..."
                          className="mt-2 p-2 w-full h-20 rounded-md border-none focus:outline-none bg-gray-100"
                        />

                        <div className="flex justify-end items-center gap-2 mt-2">
                          <label
                            htmlFor={`upload-image-${index}`}
                            className="cursor-pointer"
                          >
                            <AddPhotoAlternateIcon className="text-blue-500" />
                          </label>
                          <input
                            type="file"
                            id={`upload-image-${index}`}
                            accept="*/*"
                            style={{ display: "none" }}
                            onChange={(e) => handleImageUpload(e, item.id)}
                          />
                          <button
                            onClick={() => handleDeletePosition(item.id)} 
                            className="text-gray-400"
                            aria-label="Delete Position"
                          >
                            <DeleteIcon />
                          </button>
                        </div>
                      </div>
                    )
                )}
              </div>
              <div className="grid grid-cols-3 gap-2 mt-2">
                {noteData?.attachments?.map((file, imgIndex) => {
                  const isImage =
                    (file.type && file.type.startsWith("image/")) ||
                    /\.(jpeg|jpg|png|gif)$/i.test(file.name);

                  // const restoredFile =
                  //   file instanceof File && file.type
                  //     ? file
                  //     : new File([new Blob()], file.name, {
                  //         type: file.type || "application/octet-stream",
                  //         lastModified: file.lastModified,
                  //       });

                  return (
                    <div key={imgIndex} className="relative">
                      {isImage ? (
                        <img
                          src={file.url} 
                          alt={`Uploaded ${imgIndex + 1}`}
                          className="w-full h-20 object-cover rounded-md"
                        />
                      ) : (
                        <div className="w-full h-20 bg-gray-200 flex items-center justify-center rounded-md text-center">
                          {/* {file && file instanceof Blob ? (
                            <a
                              href={URL.createObjectURL(file)}
                              download={file.name}
                              className="text-gray-600"
                              target="_blank"
                              rel="noopener noreferrer"
                            >
                              {file.name}
                            </a>
                          ) : (
                            <div>No valid file available</div>
                          )} */}
                        </div>
                      )}

                      <button
                        onClick={() => handleMainImageDelete(file, imgIndex)}
                        className="absolute top-1 right-1 rounded-full p-1 shadow-md"
                      >
                        <HighlightOffIcon className="text-white" />
                      </button>
                    </div>
                  );
                })}
              </div>

              <textarea
                value={mainNoteText}
                onChange={handleMainNoteTextChange}
                placeholder="เขียนบันทึกที่นี่..."
                className="mt-2 p-2 w-full h-24 rounded-md border-none focus:outline-none bg-gray-100"
              />

              <div className="flex justify-end items-center gap-2 mt-2">
                <label htmlFor="upload-main-image" className="cursor-pointer">
                  <AddPhotoAlternateIcon className="text-blue-500" />
                </label>
                <input
                  type="file"
                  id="upload-main-image"
                  accept="*/*"
                  style={{ display: "none" }}
                  onChange={handleMainNoteImageUpload}
                />
              </div>
            </div>
          </div>
        )}

        {selectedLayer &&
          !("items" in selectedLayer) &&
          selectedLayer?.id.split("-")[1] == "symbol" && (
            <div
              className="fixed top-4 left-[330px] shadow-lg grid gap-2"
              style={{ zIndex: 1000 }}
            >
              <div className="bg-white p-3 rounded-md">
                <div className="text-sm font-bold">
                  {"title" in selectedLayer
                    ? selectedLayer.title
                    : "No title available"}
                </div>
                {/* <div>Layer ID: {selectedLayer.id}</div> */}
                {selectedButton === "symbol" && (
                  <div className="text-sm text-stone-500">
                    คลิกบนแผนที่เพื่อเพิ่มสัญลักษณ์
                  </div>
                )}
                {selectedButton === "path" && (
                  <div className="text-sm text-stone-500">
                    คลิกบนแผนที่เพื่อเพิ่มเส้นทาง
                  </div>
                )}
              </div>
              <div className="bg-stone-200 p-0.5 rounded-md ">
                <div className="grid grid-cols-2">
                  <button
                    onClick={() => setSelectedButton("symbol")}
                    className={`flex items-center justify-center px-4 py-1 text-sm rounded-md  transition duration-200 ease-in-out  ${
                      selectedButton === "symbol"
                        ? "bg-white text-stone-500"
                        : "bg-stone-200 text-black opacity-70"
                    }`}
                  >
                    <LocationOnIcon className="text-base" />
                    <span className="ml-2 text-sm">เพิ่มสัญลักษณ์</span>
                  </button>
                  <button
                    onClick={() => setSelectedButton("path")}
                    className={`flex items-center justify-center px-4 py-1 text-sm rounded-md  transition duration-200 ease-in-out ${
                      selectedButton === "path"
                        ? "bg-white text-stone-500"
                        : "bg-stone-200 text-black opacity-70"
                    }`}
                  >
                    <TimelineIcon className="text-base" />
                    <span className="ml-2 text-sm">เพิ่มเส้นทาง</span>
                  </button>
                </div>
              </div>
            </div>
          )}
        {isCreatingBuilding && (
          <div
            className="fixed top-4 left-[330px] shadow-lg grid gap-2"
            style={{ zIndex: 1000 }}
          >
            <div className="bg-white p-3 rounded-md">
              <div className="text-sm font-bold">แผนที่ฐาน</div>
              {/* <div>Layer ID: {selectedLayer.id}</div> */}
              {selectedMode === "Add" && (
                <div className="text-sm text-stone-500">
                  คลิกบนแผนที่เพื่อเพิ่มสิ่งก่อสร้าง
                </div>
              )}
              {selectedMode === "Delete" && (
                <div className="text-sm text-stone-500">
                  คลิกบนสิ่งก่อสร้างเพื่อลบ
                </div>
              )}
              {selectedMode === "Text" && (
                <div className="text-sm text-stone-500">
                  คลิกบนแผนที่เพื่อเพิ่มตัวอักษร
                </div>
              )}
              {selectedMode === "DeleteText" && (
                <div className="text-sm text-stone-500">
                  คลิกบนแผนที่เพื่อลบตัวอักษร
                </div>
              )}
            </div>
            <div className="bg-stone-200 p-0.5 rounded-md ">
              <div className="grid grid-cols-2">
                <button
                  onClick={() => handleModeChange("Add")}
                  className={`flex items-center justify-center px-4 py-1 text-sm rounded-md  transition duration-200 ease-in-out  ${
                    selectedMode === "Add"
                      ? "bg-white text-stone-500"
                      : "bg-stone-200 text-black opacity-70"
                  }`}
                >
                  <DashboardCustomizeOutlined className="text-base" />
                  <span className="ml-2 text-sm">เพิ่ม Building</span>
                </button>
                <button
                  onClick={() => handleModeChange("Delete")}
                  className={`flex items-center justify-center px-4 py-1 text-sm rounded-md  transition duration-200 ease-in-out ${
                    selectedMode === "Delete"
                      ? "bg-white text-stone-500"
                      : "bg-stone-200 text-black opacity-70"
                  }`}
                >
                  <Delete className="text-base" />
                  <span className="ml-2 text-sm">ลบ Building</span>
                </button>
                <button
                  onClick={() => handleModeChange("Text")}
                  className={`flex items-center justify-center px-4 py-1 text-sm rounded-md  transition duration-200 ease-in-out ${
                    selectedMode === "Text"
                      ? "bg-white text-stone-500"
                      : "bg-stone-200 text-black opacity-70"
                  }`}
                >
                  <TextIncrease className="text-base" />
                  <span className="ml-2 text-sm">เพิ่มตัวอักษร</span>
                </button>
                <button
                  onClick={() => handleModeChange("DeleteText")}
                  className={`flex items-center justify-center px-4 py-1 text-sm rounded-md  transition duration-200 ease-in-out ${
                    selectedMode === "DeleteText"
                      ? "bg-white text-stone-500"
                      : "bg-stone-200 text-black opacity-70"
                  }`}
                >
                  <TextDecrease className="text-base" />
                  <span className="ml-2 text-sm">ลบตัวอักษร</span>
                </button>
              </div>
            </div>
          </div>
        )}
        {selectedLayer?.id.startsWith("layer-form-") && (
          <div
            className="fixed top-4 left-[330px] shadow-lg grid gap-2"
            style={{ zIndex: 1000 }}
          >
            <div className="bg-white p-3 rounded-md">
              <div className="text-sm font-bold">แบบฟอร์ม</div>
              {/* <div>Layer ID: {selectedLayer.id}</div> */}

              <div className="text-sm text-stone-500">
                คลิกบน Building เพื่อกรอกข้อมูล
              </div>
            </div>
            <div className="bg-stone-200 p-0.5 rounded-md ">
              <div className="grid grid-cols-1">
                <button
                  onClick={handleOpenPopup}
                  // onClick={() => handleModeChange("Add")}
                  className="flex items-center justify-center px-4 py-1 text-sm rounded-md bg-stone-200 hover:bg-stone-100  text-stone-500  transition duration-200 ease-in-out"
                >
                  <DashboardCustomizeOutlined className="text-base" />
                  <span className="ml-2 text-sm">แก้ไขแบบฟอร์ม</span>
                </button>
              </div>
            </div>
          </div>
        )}
        {isPopupVisible && (
          <div
            style={{ zIndex: 1000 }}
            className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50"
          >
            <div className="bg-white p-6 rounded-lg shadow-lg  w-2/5 h-5/6 ">
              <h2 className="font-semibold mb-4 text-blue-500">
                แก้ไขแบบฟอร์ม
              </h2>

              <div
                style={{ maxHeight: "60vh" }}
                className="bg-stone-100 rounded flex flex-col overflow-y-auto px-2"
              >
                <div
                  onClick={() => setShowAddQuestionMenu(!showAddQuestionMenu)}
                  className="flex  text-sm text-blue-600 cursor-pointe px-2 py-4"
                >
                  เพิ่มคำถาม
                </div>
                {showAddQuestionMenu && (
                  <div className="absolute  mt-2 bg-white border rounded p-2 shadow-lg z-10 text-sm">
                    <div
                      className="cursor-pointer p-2 hover:bg-gray-200"
                      onClick={() => handleAddQuestion("text")}
                    >
                      เพิ่มคำถามแบบข้อความ
                    </div>
                    <div
                      className="cursor-pointer p-2 hover:bg-gray-200"
                      onClick={() => handleAddQuestion("number")}
                    >
                      เพิ่มคำถามแบบตัวเลข
                    </div>
                    <div
                      className="cursor-pointer p-2 hover:bg-gray-200"
                      onClick={() => handleAddQuestion("multiple_choice")}
                    >
                      เพิ่มคำถามแบบตัวเลือก
                    </div>
                    <div
                      className="cursor-pointer p-2 hover:bg-gray-200"
                      onClick={() => handleAddQuestion("checkbox")} 
                    >
                      เพิ่มคำถามแบบ Checkbox
                    </div>
                  </div>
                )}
                {selectedLayer &&
                isLayer(selectedLayer) &&
                selectedLayer.questions &&
                selectedLayer.questions.length > 0 ? (
                  selectedLayer.questions.map((question, index) => (
                    <div className="grid gap-2 p-4" key={question.id}>
                      <div className="flex justify-between items-center">
                        <input
                          className="w-full h-10 rounded text-sm px-2 bg-stone-100"
                          placeholder="แก้ไขคำถามที่นี่"
                          value={question.label}
                          onChange={(e) =>
                            handleLabelChange(question.id, e.target.value)
                          }
                        />
                        <div className="flex text-xs gap-2 items-center">
                          <button
                            onClick={() => moveQuestionUp(index)}
                            className={`text-blue-600 ${
                              index === 0 && "opacity-50 cursor-not-allowed"
                            }`}
                            disabled={index === 0}
                          >
                            <ArrowDropUpIcon />
                          </button>
                          <button
                            onClick={() => moveQuestionDown(index)}
                            className={`text-blue-600 ${
                              index === selectedLayer.questions.length - 1 &&
                              "opacity-50 cursor-not-allowed"
                            }`}
                            disabled={
                              index === selectedLayer.questions.length - 1
                            }
                          >
                            <ArrowDropDownIcon />
                          </button>
                          <button
                            onClick={() => handleDeleteQuestion(question.id)}
                            className="text-red-600"
                          >
                            &#10005;
                          </button>
                        </div>
                      </div>

                      {question.type === "text" && (
                        <input
                          className="w-full h-10 rounded text-sm px-2"
                          placeholder={question.label}
                          type="text"
                        />
                      )}

                      {question.type === "number" && (
                        <input
                          type="number"
                          step="0.01"
                          value={question.answer || ""}
                          onChange={(e) =>
                            handleNumberChange(question.id, e.target.value)
                          }
                          className="w-full h-10 rounded text-sm px-2"
                          placeholder={question.label}
                        />
                      )}

                      {question.type === "multiple_choice" && (
                        <div className="bg-white rounded p-4 text-sm w-full gap-1 grid">
                          {question.showMapToggle && (
                            <div className="flex gap-2 p-1 content-center text-xs text-blue-500 justify-end items-center">
                              <input
                                type="radio"
                                checked={question.showOnMap}
                                // onChange={() =>
                                //   handleShowOnMapToggle(question.id)
                                // }
                              />
                              <label>แสดงสีในแผนที่</label>
                            </div>
                          )}
                          {question.options?.map((option, index) => (
                            <div
                              key={option.value}
                              className="flex items-center gap-x-2"
                            >
                              <label className="flex items-center gap-x-2 w-full">
                                <input
                                  type="radio"
                                  name={question.id}
                                  value={option.value}
                                  className="mr-2"
                                />
                                <input
                                  type="text"
                                  value={option.label}
                                  onChange={(e) =>
                                    handleOptionLabelChange(
                                      question.id,
                                      index,
                                      e.target.value
                                    )
                                  }
                                  className="border bg-stone-100 rounded p-1 w-full"
                                />
                              </label>
                              {question.showOnMap && (
                                <div className="w-6 flex justify-center">
                                  <div>
                                    {showColorPicker &&
                                      activeColorOption &&
                                      activeColorOption.index === index &&
                                      (!question.options?.[index]?.color ||
                                        question.options?.[index]?.color ===
                                          "transparent") && (
                                        <ColorPicker
                                          colors={colors.filter(
                                            (color) =>
                                              !question.options?.some(
                                                (opt) => opt.color === color
                                              ) // Filter out already used colors
                                          )}
                                          onSelectColor={(selectedColor) =>
                                            handleSelectColor(
                                              question.id,
                                              index,
                                              selectedColor
                                            )
                                          }
                                          onClose={closeColorPicker}
                                        />
                                      )}

                                    <div
                                      onClick={() =>
                                        openColorPicker(question.id, index)
                                      } 
                                      style={{
                                        backgroundColor:
                                          question.options?.[index]?.color ||
                                          "transparent", 
                                      }}
                                      className="w-5 h-5 border rounded-full mt-2 cursor-pointer"
                                    />
                                  </div>
                                </div>
                              )}

                              <button
                                onClick={() =>
                                  handleRemoveOption(question.id, index)
                                }
                                className="text-stone-400 ml-2"
                              >
                                &#10005;
                              </button>
                            </div>
                          ))}

                          <div className="flex justify-start justify-center pt-2 gap-2 content-center items-center">
                            <AddIcon className="text-blue-600 text-sm" />
                            <button
                              onClick={() => handleAddOption(question.id)}
                              className="text-blue-600 text-sm"
                            >
                              เพิ่มตัวเลือก
                            </button>
                          </div>
                        </div>
                      )}

                      {question.type === "checkbox" && (
                        <div className="bg-white rounded p-4 text-sm w-full gap-1 grid">
                          {question.showMapToggle && (
                            <div className="flex gap-2 p-1 content-center text-xs text-blue-500 justify-end items-center">
                              <input
                                type="checkbox"
                                checked={question.showOnMap}
                                // onChange={() =>
                                //   handleShowOnMapToggle(question.id)
                                // }
                              />
                              <label>แสดงสีในแผนที่</label>
                            </div>
                          )}

                          {question.options?.map((option, index) => (
                            <div
                              key={option.value}
                              className="flex items-center gap-x-2"
                            >
                              <label className="flex items-center gap-x-2 w-full">
                                <input
                                  type="checkbox"
                                  name={question.id}
                                  value={option.value}
                                  // checked={option.checked}

                                  className="mr-2"
                                />
                                <input
                                  type="text"
                                  value={option.label}
                                  onChange={(e) =>
                                    handleOptionLabelChange(
                                      question.id,
                                      index,
                                      e.target.value
                                    )
                                  }
                                  className="border bg-stone-100 rounded p-1 w-full"
                                />
                              </label>
                              <button
                                onClick={() =>
                                  handleRemoveOption(question.id, index)
                                }
                                className="text-stone-400 ml-2"
                              >
                                &#10005;
                              </button>
                            </div>
                          ))}

                          <div className="flex justify-start justify-center pt-2 gap-2 content-center items-center">
                            <AddIcon className="text-blue-600 text-sm" />
                            <button
                              onClick={() => handleAddOption(question.id)}
                              className="text-blue-600 text-sm"
                            >
                              เพิ่มตัวเลือก
                            </button>
                          </div>
                        </div>
                      )}
                    </div>
                  ))
                ) : (
                  <p className="text-gray-500">ไม่มีคำถามใน Layer นี้</p>
                )}
              </div>

              <div className="flex  justify-end gap-3 py-4">
                <button
                  className="mt-4 text-blue-500 font-bold rounded py-2"
                  onClick={handleClosePopup} 
                >
                  ยกเลิก
                </button>
                <button
                  className="mt-4 bg-blue-500 hover:bg-blue-600 text-white w-24 rounded py-2 px-6 duration-300 ease-in-out transform"
                  onClick={handleFormConfirm}
                >
                  ยืนยัน
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ProjectSidebar;
