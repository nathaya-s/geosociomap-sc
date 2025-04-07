"use client";

import React, { useEffect, useRef, useState } from "react";
import mapboxgl from "mapbox-gl";
import { Popup, MapMouseEvent } from "mapbox-gl";
import "mapbox-gl/dist/mapbox-gl.css";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import { createRoot } from "react-dom/client";
// import * as turf from "@turf/turf";
// import { StaticImageData } from "next/image";
// import { Feature, LineString } from "geojson";

// import html2canvas from "html2canvas";

import LocationCityIcon from "@mui/icons-material/LocationCity";
import DirectionsCarFilledIcon from "@mui/icons-material/DirectionsCarFilled";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import HomeRepairServiceIcon from "@mui/icons-material/HomeRepairService";
import LocalConvenienceStoreIcon from "@mui/icons-material/LocalConvenienceStore";
import LocalHospitalIcon from "@mui/icons-material/LocalHospital";
import MedicalServicesIcon from "@mui/icons-material/MedicalServices";
import MovieCreationIcon from "@mui/icons-material/MovieCreation";
import MosqueIcon from "@mui/icons-material/Mosque";
import ChurchIcon from "@mui/icons-material/Church";
import CoffeeIcon from "@mui/icons-material/Coffee";
import FastfoodIcon from "@mui/icons-material/Fastfood";
import ForestIcon from "@mui/icons-material/Forest";
import GrassIcon from "@mui/icons-material/Grass";
import HotelIcon from "@mui/icons-material/Hotel";
import HouseboatIcon from "@mui/icons-material/Houseboat";
import LandslideIcon from "@mui/icons-material/Landslide";
import LocalFloristIcon from "@mui/icons-material/LocalFlorist";
import SailingIcon from "@mui/icons-material/Sailing";
import SmokeFreeIcon from "@mui/icons-material/SmokeFree";
// import ParkIcon from "@mui/icons-material/Park";
import WarehouseIcon from "@mui/icons-material/Warehouse";
import ShoppingBagIcon from "@mui/icons-material/ShoppingBag";
import CircleIcon from "@mui/icons-material/Circle";
import TextPopup from "./TextPopup";
// import { SvgIconProps } from "@mui/material/SvgIcon";
// import PopupMarkerComponent from "./PopupMarkerComponent";
// import PopupPathInfo from "./PopupPathInfo";
import PathPopup from "./PopupPathInfo";
import { v4 as uuidv4 } from "uuid";
import { Layer } from "../types/layer";
import { IconMarker } from "../types/layer";
import { Path } from "../types/layer";
import { BuildingAnswer, Relationship } from "../types/relationship";
import EditPopup from "./EditPopup";
import {
  // NoteItem,
  // MainNote,
  PositionNote,
  // SubNote,
  NoteSequence,
} from "../types/note";
import { LayerData, Question } from "../types/form";
import BuildingPopup from "./BuildingPopup";
// import { Build } from "@mui/icons-material";
import { useAuth } from "../hooks/useAuth";
import { Building } from "../types/building";

mapboxgl.accessToken = process.env.NEXT_PUBLIC_MAPBOX_TOKEN || "";

// type IconComponent = React.ComponentType<SvgIconProps>;

interface Point {
  lat: number;
  lng: number;
}

interface TextInfo {
  coordinates: [number, number]; // Assuming coordinates are a tuple of two numbers
  description: string;
}

interface ProjectMapProps {
  selectedPoints?: Point[];
  selectedButton?: string;
  layers: Layer[];
  selectedLayer: Layer | NoteSequence | null;
  noteData: NoteSequence | null;
  setNoteData: React.Dispatch<React.SetStateAction<NoteSequence | null>>;
  setLayers: (layers: Layer[]) => void;
  setSelectedLayer: (layer: Layer | NoteSequence | null) => void; // Pass setSelectedLayer function as a prop
  selectedOptions: { [key: string]: string[] };
  selectedLayerData: { data: LayerData[]; layerId: string } | null;
  isCreatingBuilding: boolean;
  projectId: string | null;
  isDeletingBuilding: boolean;
  selectedMode: "Add" | "Delete" | "Text" | "DeleteText" | null; // เพิ่ม selectedMode
  setIsFetching: React.Dispatch<React.SetStateAction<boolean>>;
}

const PopupComponent: React.FC<{
  title: string;
  description: string;
  lng: number;
  lat: number;
  color: string;
  iconName: string;
  onClose: () => void;
  onDelete: () => void;
  onSave: (
    title: string,
    description: string,
    color: string,
    iconName: string,
    imageUrls: string[]
  ) => void; // Updated type
}> = ({
  title,
  description,
  lng,
  lat,
  color,
  iconName,
  onClose,
  onSave,
  onDelete,
}) => {
  const [markerTitle, setMarkerTitle] = useState(title);
  const [markerDescription, setMarkerDescription] = useState(description);
  const [markerColor, setMarkerColor] = useState(color); 
  const [iconColor, setIconColor] = useState(color); 
  const [selectedIconName, setSelectedIconName] = useState<string | null>(
    iconName
  ); 

  const colors = [
    "#60a5fa", // สีฟ้า
    "#34d399", // สีเขียว
    "#facc15", // สีเหลือง
    "#f87171", // สีแดง
    "#c084fc", // สีม่วง
    "#818cf8", // สีน้ำเงิน
    "#a8a29e", // สีเทา
  ];

  const iconList = [
    { Icon: LocationOnIcon, label: "ตำแหน่ง", name: "LocationOnIcon" },
    { Icon: LocationCityIcon, label: "เมือง", name: "LocationCityIcon" },
    {
      Icon: DirectionsCarFilledIcon,
      label: "รถยนต์",
      name: "DirectionsCarFilledIcon",
    },
    { Icon: AccountBalanceIcon, label: "ธนาคาร", name: "AccountBalanceIcon" },
    {
      Icon: HomeRepairServiceIcon,
      label: "โรงเรียน",
      name: "HomeRepairServiceIcon",
    },
    {
      Icon: LocalConvenienceStoreIcon,
      label: "ร้านสะดวกซื้อ",
      name: "LocalConvenienceStoreIcon",
    },
    { Icon: LocalHospitalIcon, label: "โรงพยาบาล", name: "LocalHospitalIcon" },
    {
      Icon: MedicalServicesIcon,
      label: "การแพทย์",
      name: "MedicalServicesIcon",
    },
    { Icon: MovieCreationIcon, label: "ภาพยนตร์", name: "MovieCreationIcon" },
    { Icon: MosqueIcon, label: "มัสยิด", name: "MosqueIcon" },
    { Icon: ChurchIcon, label: "โบสถ์", name: "ChurchIcon" },
    { Icon: CoffeeIcon, label: "ร้านกาแฟ", name: "CoffeeIcon" },
    { Icon: FastfoodIcon, label: "ฟาสต์ฟู้ด", name: "FastfoodIcon" },
    { Icon: ForestIcon, label: "ป่า", name: "ForestIcon" },
    { Icon: GrassIcon, label: "หญ้า", name: "GrassIcon" },
    { Icon: HotelIcon, label: "โรงแรม", name: "HotelIcon" },
    { Icon: HouseboatIcon, label: "เรือบ้าน", name: "HouseboatIcon" },
    { Icon: LandslideIcon, label: "ดินถล่ม", name: "LandslideIcon" },
    { Icon: LocalFloristIcon, label: "ดอกไม้", name: "LocalFloristIcon" },
    { Icon: SailingIcon, label: "แล่นเรือ", name: "SailingIcon" },
    { Icon: SmokeFreeIcon, label: "ไม่สูบบุหรี่", name: "SmokeFreeIcon" },
    { Icon: WarehouseIcon, label: "คลังสินค้า", name: "WarehouseIcon" },
    { Icon: ShoppingBagIcon, label: "ห้าง", name: "ShoppingBagIcon" },
    { Icon: CircleIcon, label: "วงกลม", name: "CircleIcon" },
  ];

  // const [selectedIcon, setSelectedIcon] = useState<IconComponent | null>(null);

  // Inside your icon selection logic, set the selected icon
  const handleIconSelect = (iconName: string) => {
    setSelectedIconName(iconName);
  };

  useEffect(() => {
    setMarkerColor(color);
    setIconColor(color);
  }, [color]); 

  const handleSave = () => {
    if (selectedIconName) {
      onSave(markerTitle, markerDescription, markerColor, selectedIconName, []); 
    } else {
      console.error("No icon selected."); 
    }
    onClose();
  };

  const handleDelete = () => {
    onDelete(); 
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
          <div className="flex gap-2 text-blue-600 text-sm">
            <p>{lat.toPrecision(7)}</p>
            <p>{lng.toPrecision(8)}</p>
          </div>
          <div className="flex flex-col">
            <label className="text-sm">ชื่อสัญลักษณ์</label>
            <input
              type="text"
              value={markerTitle}
              onChange={(e) => setMarkerTitle(e.target.value)}
              className="mb-2 p-2 border"
            />
          </div>
          <div className="flex flex-col">
            <label className="text-sm">คำอธิบาย</label>
            <input
              type="text"
              value={markerDescription}
              onChange={(e) => setMarkerDescription(e.target.value)}
              className="mb-2 p-2 border"
            />
          </div>
          <div className="h-44 overflow-y-scroll p-2">
            <div className="grid grid-cols-4 gap-2">
              {iconList.map(({ Icon, label, name }, index) => (
                <div
                  key={index}
                  onClick={() => handleIconSelect(name)} 
                  className="flex flex-col items-center cursor-pointer"
                >
                  <div
                    className={`flex flex-col items-center cursor-pointer ${
                      selectedIconName === name ? "bg-blue-100" : "bg-stone-100"
                    } w-10 h-10 rounded p-2`}
                  >
                    <Icon style={{ color: iconColor }} />
                  </div>
                  <span className="text-[10px] text-center">{label}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="grid grid-cols-7 gap-2">
            {colors.map((color) => (
              <div
                key={color}
                onClick={() => {
                  setMarkerColor(color);
                  setIconColor(color);
                }}
                className={`w-8 h-8 cursor-pointer rounded-full ${
                  markerColor === color ? "border-2 border-black" : ""
                }`}
                style={{ backgroundColor: color }}
              />
            ))}
          </div>
          <div className="flex justify-between py-2">
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
    </div>
  );
};

interface SelectedLayerData {
  data: LayerData[]; 
  layerId: string; 
}

const ProjectMap: React.FC<ProjectMapProps> = ({
  selectedPoints,
  selectedButton,
  layers,
  setLayers,
  selectedLayer,
  setSelectedLayer,
  noteData,
  setNoteData,
  selectedOptions,
  selectedLayerData,
  isCreatingBuilding,
  projectId,
  setIsFetching,
  // isDeletingBuilding,
  selectedMode,
}) => {
  const hasFetched = useRef(false);
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const { user } = useAuth();
  const [solidLine, setSolidLine] = useState("มีความสัมพันธ์กัน");
  const [parallelLine, setParallelLine] = useState("เส้นขนาน");
  const [zigzagLine, setZigzagLine] = useState("ขัดแย้ง");
  const [dashedLine, setDashedLine] = useState("เส้นประ");
  // const [linePoints, setLinePoints] = useState<[number, number][]>([]); 
  const [tempPoints, setTempPoints] = useState<[number, number][]>([]); 
  const [isDrawingPath, setIsDrawingPath] = useState(false); 
  // const [symbols, setSymbols] = useState<
  //   { layerId: string; coords: [number, number] }[]

  // >([]);
  const [map, setMap] = useState<mapboxgl.Map | null>(null); 
  const [markerRoots, setMarkerRoots] = useState<{
    [key: string]: ReturnType<typeof createRoot>;
  }>({});
  // const [popupContent, setPopupContent] = useState<{
  //   title: string;
  //   description: string;
  // } | null>(null);
  const [layerMarkers, setLayerMarkers] = useState<{
    [key: string]: IconMarker[]; 
  }>({});

  // const handleCapture = () => {
  //   // Check if the mapContainerRef is valid
  //   if (mapContainerRef.current) {
  //     html2canvas(mapContainerRef.current).then((canvas) => {
  //       // Convert canvas to image (base64)
  //       const image = canvas.toDataURL("image/png");

  //       // Create an anchor element to download the image
  //       const link = document.createElement("a");
  //       link.href = image;
  //       link.download = "map-image.png"; 
  //       link.click();
  //     });
  //   }
  // };

  //   useEffect(() => {
  //     if (noteData?.items && Array.isArray(noteData.items)) {
  //       // สร้าง markers ใหม่สำหรับ note
  //       const noteMarkers = noteData.items.map((item) => ({
  //         lat: item.latitude,
  //         lng: item.longitude,
  //         color: "#60a5fa",
  //         description: "คำอธิบาย",
  //         iconName: "CircleIcon",
  //         name: "ชื่อ",
  //         imageUrls: [],
  //       }));

  //       // อัปเดตเฉพาะ note ใน layerMarkers
  //       setLayerMarkers((prevLayerMarkers) => ({
  //         ...prevLayerMarkers, 
  //         note: noteMarkers,  
  //       }));

  //       console.log("Updated layerMarkers: ", {
  //         ...layerMarkers,
  //         note: noteMarkers,
  //       });
  //     }
  //   }, [noteData]);

  useEffect(() => {
    const fetchNoteData = async () => {
      if (!projectId || !user?.uid) return;

      try {
        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
        const response = await fetch(
         `${API_BASE_URL}/notes/${projectId}/${user?.uid}`,
          {
            method: "GET",
            headers: {
              "Content-Type": "application/json",
            },
          }
        );

        if (!response.ok) {
          throw new Error(`Failed to fetch note: ${response.statusText}`);
        } else {
          setIsFetching(true);
        }

        const data = await response.json();
        setNoteData(data);
      } catch (error) {
        console.error(error);
      }
    };

    fetchNoteData();
  }, [projectId, user, map]);

  useEffect(() => {
    if (!map || !noteData) return;

    const markerClass = "custom-marker";

    const removeMarkers = () => {
      document
        .querySelectorAll(`.${markerClass}`)
        .forEach((marker) => marker.remove());
    };


    const createMarkers = (items: PositionNote[]) => {
      items.forEach((item) => {
        const el = document.createElement("div");
        el.className = markerClass;
        el.style.width = "10px";
        el.style.height = "10px";
        el.style.backgroundColor = "#3b82f6";
        el.style.borderRadius = "50%";

        new mapboxgl.Marker(el)
          .setLngLat([item.longitude, item.latitude])
          .addTo(map);
      });
    };

    removeMarkers();

    if (noteData.visible) {
      createMarkers(noteData.items);
    }
  }, [noteData, map]);

  
  useEffect(() => {
    if (projectId && user?.uid && map && layers.length != 0 && !hasFetched.current) {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      fetch(
       `${API_BASE_URL}/layers/${projectId}?userId=${user?.uid}`
      )
        .then((response) => response.json())
        .then((data) => {
          hasFetched.current = true; 
          if (Array.isArray(data) && map) {
            console.log("Initializing layers and markers");

            const updatedLayers = data.map((layer: Layer) => {
              if (Array.isArray(layer.markers)) {
                const updatedMarkers = layer.markers.map((marker) => {
                  const markerDiv = document.createElement("div");
                  const iconName = marker.iconName;

                  if (iconName === "CircleIcon") {
                    markerDiv.style.width = "15px";
                    markerDiv.style.height = "15px";
                  } else {
                    markerDiv.style.width = "40px";
                    markerDiv.style.height = "40px";
                  }

                  const markerKey = `${layer.id}-${marker.lng}-${marker.lat}`;
                  markerDiv.setAttribute("data-marker-key", markerKey);

                  let existingRoot = markerRoots[markerKey];
                  if (!existingRoot) {
                    existingRoot = createRoot(markerDiv);
                    setMarkerRoots((prev) => ({
                      ...prev,
                      [markerKey]: existingRoot,
                    }));

                    const mapboxMarker = new mapboxgl.Marker(markerDiv)
                      .setLngLat([marker.lng, marker.lat])
                      .addTo(map);

                    console.log(mapboxMarker);

                    addHoverListeners(
                      markerDiv,
                      marker.lng,
                      marker.lat,
                      marker.name,
                      marker.description,
                      // marker.imageUrls || [],
                      popup,
                      map
                    );

                    const iconMapping: Record<
                      | "LocationOnIcon"
                      | "LocationCityIcon"
                      | "DirectionsCarFilledIcon"
                      | "AccountBalanceIcon"
                      | "HomeRepairServiceIcon"
                      | "LocalConvenienceStoreIcon"
                      | "LocalHospitalIcon"
                      | "MedicalServicesIcon"
                      | "MovieCreationIcon"
                      | "MosqueIcon"
                      | "ChurchIcon"
                      | "CoffeeIcon"
                      | "FastfoodIcon"
                      | "ForestIcon"
                      | "GrassIcon"
                      | "HotelIcon"
                      | "HouseboatIcon"
                      | "LandslideIcon"
                      | "LocalFloristIcon"
                      | "SailingIcon"
                      | "SmokeFreeIcon"
                      | "WarehouseIcon"
                      | "ShoppingBagIcon"
                      | "CircleIcon",
                      { Icon: React.ElementType; size: number }
                    > = {
                      LocationOnIcon: {
                        Icon: LocationOnIcon,
                        size: 40,
                      },
                      LocationCityIcon: {
                        Icon: LocationCityIcon,
                        size: 40,
                      },
                      DirectionsCarFilledIcon: {
                        Icon: DirectionsCarFilledIcon,
                        size: 40,
                      },
                      AccountBalanceIcon: {
                        Icon: AccountBalanceIcon,
                        size: 40,
                      },
                      HomeRepairServiceIcon: {
                        Icon: HomeRepairServiceIcon,
                        size: 40,
                      },
                      LocalConvenienceStoreIcon: {
                        Icon: LocalConvenienceStoreIcon,
                        size: 40,
                      },
                      LocalHospitalIcon: {
                        Icon: LocalHospitalIcon,
                        size: 40,
                      },
                      MedicalServicesIcon: {
                        Icon: MedicalServicesIcon,
                        size: 40,
                      },
                      MovieCreationIcon: {
                        Icon: MovieCreationIcon,
                        size: 40,
                      },
                      MosqueIcon: {
                        Icon: MosqueIcon,
                        size: 40,
                      },
                      ChurchIcon: {
                        Icon: ChurchIcon,
                        size: 40,
                      },
                      CoffeeIcon: {
                        Icon: CoffeeIcon,
                        size: 40,
                      },
                      FastfoodIcon: {
                        Icon: FastfoodIcon,
                        size: 40,
                      },
                      ForestIcon: {
                        Icon: ForestIcon,
                        size: 40,
                      },
                      GrassIcon: {
                        Icon: GrassIcon,
                        size: 40,
                      },
                      HotelIcon: {
                        Icon: HotelIcon,
                        size: 40,
                      },
                      HouseboatIcon: {
                        Icon: HouseboatIcon,
                        size: 40,
                      },
                      LandslideIcon: {
                        Icon: LandslideIcon,
                        size: 40,
                      },
                      LocalFloristIcon: {
                        Icon: LocalFloristIcon,
                        size: 40,
                      },
                      SailingIcon: {
                        Icon: SailingIcon,
                        size: 40,
                      },
                      SmokeFreeIcon: {
                        Icon: SmokeFreeIcon,
                        size: 40,
                      },
                      WarehouseIcon: {
                        Icon: WarehouseIcon,
                        size: 40,
                      },
                      ShoppingBagIcon: {
                        Icon: ShoppingBagIcon,
                        size: 40,
                      },
                      CircleIcon: {
                        Icon: CircleIcon,
                        size: 15,
                      },
                    };

                    interface IconRendererProps {
                      iconName: keyof typeof iconMapping; 
                      marker: { color: string };
                    }

                    const IconRenderer: React.FC<IconRendererProps> = ({
                      iconName,
                      marker,
                    }) => {
                      const iconData = iconMapping[iconName]; 
                      if (!iconData) {
                        return null; 
                      }

                      const { Icon, size } = iconData;
                      return (
                        <Icon style={{ fontSize: size, color: marker.color }} />
                      );
                    };
                    if (isMounted.current) {
                      existingRoot.render(
                        <IconRenderer
                          iconName={iconName as keyof typeof iconMapping}
                          marker={marker}
                        />
                      );
                    }

                    setLayerMarkers((prev) => ({
                      ...prev,
                      [layer.id]: [
                        ...(prev[layer.id] || []),
                        {
                          name: marker.name,
                          description: marker.description,
                          iconName,
                          color: marker.color,
                          lat: marker.lat,
                          lng: marker.lng,
                          imageUrls: marker.imageUrls || [],
                        },
                      ],
                    }));
                  }

                  return {
                    ...marker,
                    iconName,
                  };
                });

                return {
                  ...layer,
                  markers: updatedMarkers,
                };
              }
              return layer;
            });

            setLayers(updatedLayers);
          }
        })
        .catch((error) => {
          console.error("Error fetching layers:", error);
        });
    }
  }, [projectId, user?.uid, layers.length, map]);

  const [popupInfo, setPopupInfo] = useState<{
    title: string;
    description: string;
    lng: number;
    lat: number;
    color: string;
    iconName: string;
  } | null>(null);

  const [popup, setPopup] = useState<Popup | null>(null); 

  // const [selectedPath, setSelectedPath] = useState<Path | null>(null);
  // const [showPopup, setShowPopup] = useState(false);
  const [popupPathInfo, setPopupPathInfo] = useState<Path | null>(null);

  useEffect(() => {
    const newPopup = new Popup({ closeButton: false }); 
    setPopup(newPopup);
  }, []);

  const handleMapClick = useRef<(e: mapboxgl.MapMouseEvent) => void>(() => {}); 
  const iconList = [
    { Icon: LocationOnIcon, label: "ตำแหน่ง", name: "LocationOnIcon" },
    { Icon: LocationCityIcon, label: "เมือง", name: "LocationCityIcon" },
    {
      Icon: DirectionsCarFilledIcon,
      label: "รถยนต์",
      name: "DirectionsCarFilledIcon",
    },
    { Icon: AccountBalanceIcon, label: "ธนาคาร", name: "AccountBalanceIcon" },
    {
      Icon: HomeRepairServiceIcon,
      label: "โรงเรียน",
      name: "HomeRepairServiceIcon",
    },
    {
      Icon: LocalConvenienceStoreIcon,
      label: "ร้านสะดวกซื้อ",
      name: "LocalConvenienceStoreIcon",
    },
    { Icon: LocalHospitalIcon, label: "โรงพยาบาล", name: "LocalHospitalIcon" },
    {
      Icon: MedicalServicesIcon,
      label: "การแพทย์",
      name: "MedicalServicesIcon",
    },
    { Icon: MovieCreationIcon, label: "ภาพยนตร์", name: "MovieCreationIcon" },
    { Icon: MosqueIcon, label: "มัสยิด", name: "MosqueIcon" },
    { Icon: ChurchIcon, label: "โบสถ์", name: "ChurchIcon" },
    { Icon: CoffeeIcon, label: "ร้านกาแฟ", name: "CoffeeIcon" },
    { Icon: FastfoodIcon, label: "ฟาสต์ฟู้ด", name: "FastfoodIcon" },
    { Icon: ForestIcon, label: "ป่า", name: "ForestIcon" },
    { Icon: GrassIcon, label: "หญ้า", name: "GrassIcon" },
    { Icon: HotelIcon, label: "โรงแรม", name: "HotelIcon" },
    { Icon: HouseboatIcon, label: "เรือบ้าน", name: "HouseboatIcon" },
    { Icon: LandslideIcon, label: "ดินถล่ม", name: "LandslideIcon" },
    { Icon: LocalFloristIcon, label: "ดอกไม้", name: "LocalFloristIcon" },
    { Icon: SailingIcon, label: "แล่นเรือ", name: "SailingIcon" },
    { Icon: SmokeFreeIcon, label: "ไม่สูบบุหรี่", name: "SmokeFreeIcon" },
    { Icon: WarehouseIcon, label: "คลังสินค้า", name: "WarehouseIcon" },
    { Icon: ShoppingBagIcon, label: "ห้าง", name: "ShoppingBagIcon" },
    { Icon: CircleIcon, label: "วงกลม", name: "CircleIcon" },
  ];

  const getCentroid = (points: Point[]): [number, number] => {
    const totalPoints = points.length;

    const sum = points.reduce(
      (acc, point) => {
        return {
          lat: acc.lat + point.lat,
          lng: acc.lng + point.lng,
        };
      },
      { lat: 0, lng: 0 }
    );

    const centroid = {
      lat: sum.lat / totalPoints,
      lng: sum.lng / totalPoints,
    };
    console.log([centroid.lng, centroid.lat]);
    return [centroid.lng, centroid.lat];
  };

  const addHoverListeners = (
    markerDiv: HTMLElement,
    lng: number,
    lat: number,
    name: string,
    description: string,
    // imageUrls: string[] = [],
    popup: Popup | null,
    map: mapboxgl.Map | null 
  ) => {
    if (selectedLayer && "items" in selectedLayer) return;
    if (popup == null || map == null) return;
    const updatePopupContent = () => {
      console.log(selectedLayer);

      popup.setHTML(`
        <div class="bg-white px-1 rounded max-w-xs">
          <div class="text-sm font-bold">${name}</div>
          <div class="text-sm text-gray-700">${description}</div>
        </div>
      `);
    };

    markerDiv.addEventListener("mouseenter", () => {
      popup.remove();
      updatePopupContent(); 
      popup.setLngLat([lng, lat]).addTo(map); 
    });

    markerDiv.addEventListener("mouseleave", () => {
      popup.remove();
    });
  };

  const markersRef = useRef<mapboxgl.Marker[]>([]);

  useEffect(() => {
    if (!map) return;

    markersRef.current.forEach((marker) => marker.remove());
    markersRef.current = [];

    if (!noteData || !noteData.items || noteData.items.length === 0) return;

    noteData.items.forEach((item: PositionNote) => {
      if (item.type === "position") {
        const { latitude, longitude, attachments, note } = item;

        const popupContent = `
          <div class="popup-content">
            <h3>${note}</h3>
            ${
              attachments.length
                ? (() => {
                    const imageFile = attachments.find((file) =>
                      file.type.startsWith("image/")
                    );
                    return imageFile
                      ? `<img src="${imageFile.url}" alt="${imageFile.name}" class="w-full h-20 object-cover rounded-md mt-2" />`
                      : "";
                  })()
                : ""
            }
          </div>
        `;

        const popup = new mapboxgl.Popup({
          offset: 10,
          closeOnClick: false,
          closeButton: false,
        }).setHTML(popupContent);

        const markerDiv = document.createElement("div");
        markerDiv.style.width = "20px";
        markerDiv.style.height = "20px";
        markerDiv.style.backgroundColor = "transparent";
        markerDiv.style.border = "1px solid transparent";

        const marker = new mapboxgl.Marker(markerDiv)
          .setLngLat([longitude, latitude])
          .setPopup(popup)
          .addTo(map);

        markersRef.current.push(marker);
      }
    });
  }, [noteData, map]);

  const [popupMarker, setpopupMarkerInfo] = useState<NoteSequence | null>(null);

  useEffect(() => {
    setpopupMarkerInfo(null);
  }, [selectedLayer]);

  const [relationshipPoint, setRelationshipPoint] = useState<
    [number, number][]
  >([]);

  useEffect(() => {
  }, [popupMarker, relationshipPoint]);

  // const handleMarkerLeave = () => {
  //   setpopupMarkerInfo(null);
  // };

  const addMarker = (
    lng: number,
    lat: number,
    layerId: string,
    color: string,
    name: string,
    description: string,
    imageUrls: string[] = [] 
  ) => {
    if (
      map &&
      selectedLayer &&
      selectedLayer.visible &&
      selectedLayer.id === layerId
    ) {
      const iconName =
        "items" in selectedLayer ? "CircleIcon" : "LocationOnIcon"; 
      if (!layerMarkers[layerId]?.some((m) => m.lat === lat && m.lng === lng)) {
        const markerDiv = document.createElement("div");

        if ("items" in selectedLayer) {
          
          markerDiv.style.width = "15px";
          markerDiv.style.height = "15px";
        } else {
          markerDiv.style.width = "40px";
          markerDiv.style.height = "40px";
        }

        const markerKey = `${layerId}-${lng}-${lat}`;
        markerDiv.setAttribute("data-marker-key", markerKey);
        let existingRoot = markerRoots[markerKey];

        if (!existingRoot) {
          existingRoot = createRoot(markerDiv);
          setMarkerRoots((prev) => ({ ...prev, [markerKey]: existingRoot }));

          const marker = new mapboxgl.Marker(markerDiv)
            .setLngLat([lng, lat])
            .addTo(map);

          console.log(marker);

          const newMarker: IconMarker = {
            name,
            description,
            iconName,
            color,
            lat,
            lng,
            imageUrls: "items" in selectedLayer ? imageUrls : [],
          };

          if (newMarker) {
            addHoverListeners(
              markerDiv,
              lng,
              lat,
              name,
              description,
          
              popup,
              map
            );
          }
          if (!Array.isArray(layers) || layers.length < 1) return;
          const targetLayer = layers.find((layer) => layer.id === layerId);

          if (targetLayer && "markers" in targetLayer) {
            if (!targetLayer.markers) {
              targetLayer.markers = [];
            }

            targetLayer.markers.push(newMarker);
          }

       
          if (isMounted.current) {
            existingRoot.render(
              iconName === "CircleIcon" ? (
                <CircleIcon style={{ fontSize: 15, color }} />
              ) : (
                <LocationOnIcon style={{ fontSize: 40, color }} />
              )
            );
          }

          setLayerMarkers((prev) => ({
            ...prev,
            [layerId]: [...(prev[layerId] || []), newMarker],
          }));

          if ("markers" in selectedLayer) {
            const updatedMarkers = [...selectedLayer.markers, newMarker]; 
            const updatedLayer: Layer = {
              ...selectedLayer, 
              markers: updatedMarkers,
            };

     
            setSelectedLayer(updatedLayer);
          }
        } else {
          if (isMounted.current) {
            existingRoot.render(
              iconName === "CircleIcon" ? (
                <CircleIcon style={{ fontSize: 15, color }} />
              ) : (
                <LocationOnIcon style={{ fontSize: 40, color }} />
              )
            );
          }
        }
      }
    }
  };

  const isMounted = useRef(true); 

  const getIconByName = (iconName: string) => {
    const iconObj = iconList.find((icon) => icon.name === iconName);
    return iconObj ? iconObj.Icon : null;
  };

  const toggleLayerVisibility = (layerId: string, visible: boolean): void => {
    console.log("Toggling layer visibility:", { layerId, visible });

 
    if (layerMarkers[layerId]) {
      layerMarkers[layerId].forEach((marker: IconMarker) => {
        const markerKey = `${layerId}-${marker.lng}-${marker.lat}`;
        const existingRoot = markerRoots[markerKey];
        const IconComponent = getIconByName(marker.iconName);

        if (existingRoot) {
          if (visible && IconComponent) {
            existingRoot.render(
              React.createElement(IconComponent, {
                style:
                  marker.iconName === "CircleIcon"
                    ? { width: "15px", height: "15px", color: marker.color }
                    : { fontSize: 40, color: marker.color },
              })
            );
          } else {
            existingRoot.render(null);
          }
        }
      });
    }

  
    const pathLayerPrefix = `path-${layerId}`;
    if (map) {
      if (visible) {
        layers
          .find((layer) => layer.id === layerId)
          ?.paths?.forEach((path) => {
            const pathLayerId = `${pathLayerPrefix}-${path.id}`;
            if (!map.getLayer(pathLayerId)) {
              map.addLayer({
                id: pathLayerId,
                type: "line",
                source: {
                  type: "geojson",
                  data: {
                    type: "FeatureCollection",
                    features: [
                      {
                        type: "Feature",
                        geometry: {
                          type: "LineString",
                          coordinates: path.points.map((p) => [p.lng, p.lat]),
                        },
                        properties: {}, 
                      },
                    ],
                  },
                },
                layout: { visibility: visible ? "visible" : "none" },
                paint: {
                  "line-color": path.color,
                  "line-width": path.thickness,
                },
              });
            }
          });
      } else {
        layers
          .find((layer) => layer.id === layerId)
          ?.paths?.forEach((path) => {
            const pathLayerId = `${pathLayerPrefix}-${path.id}`;
            if (map.getLayer(pathLayerId)) {
              map.removeLayer(pathLayerId);
            }
            if (map.getSource(pathLayerId)) {
              map.removeSource(pathLayerId);
            }
          });
      }
    }
  };

  useEffect(() => {
    console.log("selectedLayer updated: ", selectedLayer);
  }, [selectedLayer]);

  const updateLayerInDatabase = async (
    layerId: string,
    updatedData: Partial<Layer>
  ) => {
    try {
      const requestData = {
        ...updatedData,
        userId: user?.uid,
        sharedWith: [],
        isDeleted: false,
        lastUpdate: new Date().toISOString(),
      };
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL

      const response = await fetch(
       `${API_BASE_URL}/layers/update/${layerId}`,
        {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(requestData),
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to update layer: ${response.statusText}`);
      }

      const data = await response.json();
      console.log("Layer updated successfully:", data);
    } catch (error) {
      console.error("Error updating layer:", error);
    }
  };

  useEffect(() => {
    if (
      selectedLayer &&
      selectedLayer.id &&
      "markers" in selectedLayer &&
      selectedLayer.id.startsWith("layer-symbol-")
    ) {
      updateLayerInDatabase(selectedLayer.id, selectedLayer);
    }
  }, [selectedLayer]);

  useEffect(() => {
    if (mapContainerRef.current && selectedPoints) {
      const newMap = new mapboxgl.Map({
        container: mapContainerRef.current,
        style: "mapbox://styles/mapbox/streets-v11",
        center: getCentroid(selectedPoints),
        zoom: 17,
      });
      setMap(newMap);
      const coordinates = selectedPoints.map((point) => [point.lng, point.lat]);

      coordinates.push(coordinates[0]);

      const bounds = [
        [-180, -90], 
        [-180, 90], 
        [180, 90], 
        [180, -90], 
        [-180, -90], 
      ];

      newMap.on("load", () => {
        newMap.addLayer({
          id: "outside-polygon-fill",
          type: "fill",
          source: {
            type: "geojson",
            data: {
              type: "Feature",
              geometry: {
                type: "Polygon",
                coordinates: [bounds, coordinates], 
              },
              properties: {},
            },
          },
          layout: {},
          paint: {
            "fill-color": "#3b82f6", 
            "fill-opacity": 0.1,
          },
        });

        newMap.addLayer({
          id: "polygon-outline",
          type: "line",
          source: {
            type: "geojson",
            data: {
              type: "Feature",
              geometry: {
                type: "LineString",
                coordinates: coordinates,
              },
              properties: {},
            },
          },
          layout: {
            "line-join": "round",
            "line-cap": "round",
          },
          paint: {
            "line-color": "#60a5fa",
            "line-width": 3,
          },
        });
      });
      // newMap.on("load", () => {
      //   setMap(newMap); 
      // });

      return () => {
        isMounted.current = false;
        newMap.remove();
      };
    }
  }, [selectedPoints]);

  const distanceBetweenPoints = (
    point1: [number, number],
    point2: [number, number]
  ): number => {
    const R = 6371e3;
    const lat1 = point1[1] * (Math.PI / 180);
    const lat2 = point2[1] * (Math.PI / 180);
    const deltaLat = (point2[1] - point1[1]) * (Math.PI / 180);
    const deltaLng = (point2[0] - point1[0]) * (Math.PI / 180);

    const a =
      Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
      Math.cos(lat1) *
        Math.cos(lat2) *
        Math.sin(deltaLng / 2) *
        Math.sin(deltaLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  };

  const generateUniquePathName = (baseName: string, layerId: string) => {
    let uniqueName = baseName;
    let counter = 1;

    const layer = layers.find((layer) => layer.id === layerId);

    if (layer && "markers" in layer) {
      const existingNames = layer.paths.map((path) => path.name);

      while (existingNames.includes(uniqueName)) {
        uniqueName = `${baseName} (${counter})`;
        counter++;
      }
    }

    return uniqueName;
  };

  const addPath = (layerId: string, coordinates: [number, number][]) => {
    if (coordinates.length >= 2) {
      const baseName = "New Path";
      const uniqueName = generateUniquePathName(baseName, layerId);
      const newPath: Path = {
        id: uuidv4(),
        points: coordinates.map(([lng, lat]) => ({ lng, lat })),
        color: "#f8fafc",
        thickness: 4, 
        name: uniqueName, 
        description: "Description of the new path", 
      };

      const updatedLayers = layers.map((layer) => {
        if (layer.id === layerId) {
          return {
            ...layer,
            paths: [...layer.paths, newPath],
          };
        }
        return layer;
      });

      setLayers(updatedLayers); 

      if (map) {
        console.log("Adding new path layer to map", coordinates);
        console.log("path addLayer", layerId); 

        map.addLayer({
          id: `path-${layerId}-${newPath.id}`, 
          type: "line",
          source: {
            type: "geojson",
            data: {
              type: "Feature",
              geometry: {
                type: "LineString",
                coordinates: coordinates, 
              },
              properties: {
                name: newPath.name,
                description: newPath.description,
                color: newPath.color,
                thickness: newPath.thickness,
              },
            },
          },
          layout: {
            "line-join": "round",
            "line-cap": "round",
          },
          paint: {
            "line-color": newPath.color,
            "line-width": newPath.thickness,
          },
        });
      } else {
        console.error("Map object is not available");
      }
    } else {
      console.log("Not enough points to draw a line", coordinates);
    }
  };

  const [tempLayerId, setTempLayerId] = useState<string | null>(null);

  const handlePathButtonClick = () => {
    if (isDrawingPath && tempPoints.length >= 2 && selectedLayer) {
      console.log("Saving path to layer:", selectedLayer.id);
      addPath(selectedLayer.id, tempPoints); 

      if (map && tempLayerId && map.getLayer(tempLayerId)) {
        map.removeLayer(tempLayerId);
        map.removeSource(tempLayerId);
        setTempLayerId(null);
      }

      setTempPoints([]);
      setIsDrawingPath(false);
    } else {
      setIsDrawingPath(true); 
    }
  };

  const showTempPathOnMap = (coordinates: [number, number][]) => {
    if (map && coordinates.length >= 2) {
      const layerId = `temp-path`;

      if (map.getLayer(layerId)) {
        map.removeLayer(layerId);
        map.removeSource(layerId);
      }

      map.addLayer({
        id: layerId,
        type: "line",
        source: {
          type: "geojson",
          data: {
            type: "Feature",
            geometry: {
              type: "LineString",
              coordinates: coordinates,
            },
            properties: {},
          },
        },
        layout: {
          "line-join": "round",
          "line-cap": "round",
        },
        paint: {
          "line-color": "#f8fafc",
          "line-width": 4,
        },
      });
      setTempLayerId(layerId);
      console.log("Temporary path added to map:", coordinates);
    }
  };

  const checkIfPathClicked = (clickedPoint: [number, number]): Path | null => {
    for (const layer of layers) {
      for (const path of layer.paths) {
      
        const isNearPath = path.points.some((point) => {
          return (
            Math.abs(point.lng - clickedPoint[0]) < 0.0001 &&
            Math.abs(point.lat - clickedPoint[1]) < 0.0001
          );
        });

        if (isNearPath) {
          return path; 
        }
      }
    }
    return null;
  };

  const isPointInPolygon = (
    point: [number, number],
    polygon: [number, number][]
  ): boolean => {
    const [x, y] = point;
    let inside = false;

    for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      const [xi, yi] = polygon[i];
      const [xj, yj] = polygon[j];

      const intersect =
        yi > y !== yj > y && 
        x < ((xj - xi) * (y - yi)) / (yj - yi) + xi;
      if (intersect) inside = !inside;
    }

    return inside;
  };

  useEffect(() => {
    if (map && selectedPoints) {
      handleMapClick.current = (e) => {
        const { lng, lat } = e.lngLat;
        const clickedPoint: [number, number] = [lng, lat];

      
        const coordinates: [number, number][] = selectedPoints.map(
          (point) => [point.lng, point.lat] as [number, number]
        );

        const isPointInPath = isPointInPolygon(clickedPoint, coordinates);

      
        if (
          selectedLayer &&
          selectedButton === "symbol" &&
          isPointInPath &&
          selectedLayer.id.startsWith("layer-symbol-") &&
          !("items" in selectedLayer)
        ) {
          handleSymbolClick(clickedPoint);
        } else if (
          selectedLayer &&
          selectedLayer.visible &&
          selectedLayer.id.startsWith("note") &&
          noteData?.visible
        ) {
          console.log("passsssssssssssss");
          handleNoteClick(clickedPoint, lng, lat);
        } else if (
          selectedButton === "path" &&
          isPointInPath &&
          selectedLayer?.id.startsWith("layer-symbol")
        ) {
          handlePathClick(clickedPoint);
        } else if (selectedLayer?.id.startsWith("layer-relationship")) {
          //   handleRelationship();
        } else {
          console.log("Clicked point is outside the path.");
        }
      };

      map.on("click", handleMapClick.current);

      return () => {
        map.off("click", handleMapClick.current);
      };
    }
  }, [
    map,
    selectedButton,
    selectedLayer,
    isDrawingPath,
    layerMarkers,
    layers,
    noteData,
    selectedPoints,
  ]);

  const handleSymbolClick = (clickedPoint: [number, number]) => {
    let foundNearbyMarker = false;

    for (const layerId in layerMarkers) {
      for (const marker of layerMarkers[layerId]) {
        const distance = distanceBetweenPoints(
          [marker.lng, marker.lat],
          clickedPoint
        );
        if (distance < 5) {
          foundNearbyMarker = true;
          if (selectedLayer && !("items" in selectedLayer)) {
            setPopupInfo({
              title: marker.name,
              description: marker.description,
              lng: marker.lng,
              lat: marker.lat,
              color: marker.color,
              iconName: marker.iconName,
            });
          }
          break;
        }
      }
      if (foundNearbyMarker) break;
    }

    if (
      !foundNearbyMarker &&
      selectedLayer &&
      selectedLayer.visible &&
      !("items" in selectedLayer)
    ) {
      addMarker(
        clickedPoint[0],
        clickedPoint[1],
        selectedLayer.id,
        "#60a5fa",
        "ชื่อ",
        "คำอธิบาย"
      );
    }
  };

  const handleNoteClick = (
    clickedPoint: [number, number],
    lng: number,
    lat: number
  ) => {
    let foundNearbyMarker = false;

    if (noteData?.items) {
      for (const marker of noteData.items) {
        const distance = distanceBetweenPoints(
          [marker.longitude, marker.latitude],
          clickedPoint
        );
        if (distance < 20) {
          foundNearbyMarker = true;
          break;
        }
      }
    }

    if (!foundNearbyMarker && selectedLayer && "items" in selectedLayer) {
      const newPositionNote: PositionNote = {
        type: "position",
        id: `position-${Date.now()}`,
        latitude: lat,
        longitude: lng,
        attachments: [],
        note: "",
      };

      const updatedItems = [...selectedLayer.items, newPositionNote];
      const updatedLayer: NoteSequence = {
        ...selectedLayer,
        items: updatedItems,
      };

      setSelectedLayer(updatedLayer);
      setNoteData(updatedLayer);
      console.log("PositionNote added:", newPositionNote);
    }
  };

  const handlePathClick = (clickedPoint: [number, number]) => {
    if (isDrawingPath) {
      setTempPoints((prevPoints) => {
        const newPoints = [...prevPoints, clickedPoint];
        if (newPoints.length >= 2) {
          showTempPathOnMap(newPoints);
        }
        return newPoints;
      });
    } else {
      const clickedPath = checkIfPathClicked(clickedPoint);
      if (clickedPath) {
        console.log("Clicked path found:", clickedPath);
        setPopupPathInfo(clickedPath);
      } else {
        console.log("No path found at clicked point.");
      }
    }
  };

  useEffect(() => {
    console.log("Layers updated:", layers);

    if (Array.isArray(layers) && map) {
      layers.forEach((layer) => {
        toggleLayerVisibility(layer.id, layer.visible);
      });
    } else {
      console.error("Invalid layers data:", layers);
    }
  }, [layers, map]);

  const handleClosePopup = () => {
    setPopupInfo(null);
  };
  const handleSave = (
    title: string,
    description: string,
    color: string,
    selectedIconName: string,
    imageUrls: string[]
  ) => {
    if (popupInfo) {
      const existingMarkers = layerMarkers[selectedLayer?.id || ""];

      const markerToUpdate = existingMarkers?.find(
        (marker) => marker.lng === popupInfo.lng && marker.lat === popupInfo.lat
      );

      const targetLayer = layers.find(
        (layer) => layer.id === selectedLayer?.id
      );

      if (targetLayer && markerToUpdate) {
 
        markerToUpdate.name = title;
        markerToUpdate.description = description;
        markerToUpdate.iconName = selectedIconName;
        markerToUpdate.color = color;
        markerToUpdate.imageUrls = imageUrls; 

        const updatedMarkers = existingMarkers.map((marker) =>
          marker.lng === popupInfo.lng && marker.lat === popupInfo.lat
            ? markerToUpdate
            : marker
        );
        setLayerMarkers({
          ...layerMarkers,
          [selectedLayer?.id || ""]: updatedMarkers,
        });

        const updatedLayers = layers.map((layer) => {
          if (layer.id === selectedLayer?.id) {
            return {
              ...layer,
              markers: updatedMarkers, 
            };
          }
          return layer;
        });

        setLayers(updatedLayers);
        setSelectedLayer(
          updatedLayers.find((item) => item.id === selectedLayer?.id) || null
        );

        const markerKey = `${selectedLayer?.id}-${popupInfo.lng}-${popupInfo.lat}`;
        const existingRoot = markerRoots[markerKey];

        if (existingRoot) {
          const IconComponent = getIconByName(selectedIconName);

          if (IconComponent && isMounted.current) {
            existingRoot.render(
              <IconComponent style={{ fontSize: 40, color }} />
            );
          }
          const markerDiv = document.querySelector(
            `[data-marker-key="${markerKey}"]`
          ) as HTMLElement;

          if (markerDiv) {
            addHoverListeners(
              markerDiv,
              popupInfo.lng,
              popupInfo.lat,
              title,
              description,
              // imageUrls,
              popup,
              map
            );
          }
        }
      }
      setPopupInfo(null);
    }
  };

  const deleteMarker = (lng: number, lat: number, layerId: string) => {
    const updatedMarkers = layerMarkers[layerId]?.filter(
      (marker) => marker.lng !== lng || marker.lat !== lat
    );

    if (updatedMarkers) {
      setLayerMarkers((prev) => ({
        ...prev,
        [layerId]: updatedMarkers,
      }));

      const markerKey = `${layerId}-${lng}-${lat}`;
      const existingRoot = markerRoots[markerKey];

      const updatedLayers = layers.map((layer) => {
        if (layer.id === layerId) {
          return {
            ...layer,
            markers: updatedMarkers, 
          };
        }
        return layer;
      });

      setLayers(updatedLayers);
      setSelectedLayer(
        updatedLayers.find((item) => item.id === selectedLayer?.id) || null
      );

      if (existingRoot) {
        existingRoot.unmount();
        delete markerRoots[markerKey]; 

        const markerDiv = document.querySelector(
          `[data-marker-key="${markerKey}"]`
        );
        if (markerDiv) {
          markerDiv.remove();
        }
      }
    }
  };

  const handleDeleteMarker = () => {
    if (popupInfo) {
      deleteMarker(popupInfo.lng, popupInfo.lat, selectedLayer?.id || "");
      handleClosePopup();
    }
  };

  // const [paths, setPaths] = useState<Path[]>([]);
  const handleSavePath = (
    id: string,
    name: string,
    description: string,
    color: string,
    thickness: number
  ) => {
    if (popupPathInfo) {
      console.log("Updating path with ID:", id);
      console.log("New name:", name);
      console.log("New description:", description);

      if (selectedLayer) {
        const updatedLayers = layers.map((layer) => {
          if (layer.id === selectedLayer.id) {
            const updatedPaths = layer.paths.map((path) => {
              if (path.id === id) {
                return {
                  ...path,
                  name: name,
                  description: description,
                  thickness: thickness,
                  color: color,
                };
              }
              return path;
            });

            if (!updatedPaths.some((path) => path.id === id)) {
              updatedPaths.push({
                id, 
                name,
                description,
                thickness,
                color,
                points: popupPathInfo.points,
              });
            }

            return {
              ...layer,
              paths: updatedPaths,
            };
          }
          return layer;
        });

        setLayers(updatedLayers); 

        if (map) {
          const pathLayerId = `path-${selectedLayer.id}-${id}`;
          if (map.getLayer(pathLayerId)) {
            map.removeLayer(pathLayerId);
            map.removeSource(pathLayerId); 
          }
          const updatedPath = updatedLayers
            .find((layer) => layer.id === selectedLayer.id)
            ?.paths.find((path) => path.id === id);

          if (updatedPath && updatedPath.points) {
            map.addSource(pathLayerId, {
              type: "geojson",
              data: {
                type: "Feature",
                geometry: {
                  type: "LineString",
                  coordinates: updatedPath.points.map((point) => [
                    point.lng,
                    point.lat,
                  ]), 
                },
                properties: {
                  color: updatedPath.color,
                  thickness: updatedPath.thickness,
                },
              },
            });

            map.addLayer({
              id: pathLayerId,
              type: "line",
              source: pathLayerId,
              layout: {
                "line-cap": "round",
                "line-join": "round",
              },
              paint: {
                "line-color": updatedPath.color,
                "line-width": updatedPath.thickness,
              },
            });
          }
        } else {
          console.error("Map object is not available");
        }

        setPopupPathInfo(null); 
      }
    }
  };

  const handleDeletePath = (pathId: string) => {
    if (selectedLayer) {
      if ("paths" in selectedLayer) {
        console.log("Deleting path:", pathId);
        console.log("Updated layers:", selectedLayer?.id);

        if (selectedLayer) {
          if (map) {
            selectedLayer.paths.forEach(() => {
              const pathLayerId = `path-${selectedLayer.id}-${pathId}`;
              console.log(pathLayerId);
              if (map.getLayer(pathLayerId)) {
                map.removeLayer(pathLayerId);
                map.removeSource(pathLayerId); 
              }
            });
          } else {
            console.error("Map object is not available");
          }
          if (map && tempLayerId && map.getLayer(tempLayerId)) {
            map.removeLayer(tempLayerId);
            map.removeSource(tempLayerId);
            setTempLayerId(null);
          }

          setTempPoints([]);
          const updatedLayers = layers.map((layer) => {
            if (layer.id === selectedLayer.id) {
              const updatedPaths = layer.paths.filter(
                (path) => path.id !== pathId
              );
              return {
                ...layer,
                paths: updatedPaths,
              };
            }
            return layer;
          });
          setLayers(updatedLayers);
          setSelectedLayer(
            updatedLayers.find((item) => item.id === selectedLayer.id) || null
          );
          setPopupPathInfo(null);
        }
      }
    }
  };

  const [buildingInfo, setBuildingInfo] = useState<{
    name?: string;
    id: string;
    questions: Question[];
    coordinates: number[] | number[][] | number[][][];
  } | null>(null);
  const [answers, setAnswers] = useState<
    Record<string, Record<string, string | number | string[]>>
  >({});
  const [isMapInitialized, setIsMapInitialized] = useState(false);

  const [buildingData, setBuildingData] = useState<
    Record<string, BuildingAnswer[]>
  >({});

  const handleSaveAnswers = async (
    buildingId: string,
    buildingAnswers: Record<string, string | number | string[]>,
    coordinates: number[] | number[][] | number[][][]
  ) => {
    if (!map || !selectedLayer) return;


    setAnswers((prev) => ({
      ...prev,
      [buildingId]: buildingAnswers,
    }));

    console.log(buildingAnswers);
    console.log(answers);

    let selectedColor = "#d1d5db"; 
    if ("questions" in selectedLayer) {
      const { questions } = selectedLayer;

      if (questions && Array.isArray(questions)) {
       
        questions
          .filter((question) => question.showOnMap === true)
          .forEach((question) => {
            const answerValue = buildingAnswers[question.id];
            const matchingOption = question.options?.find(
              (option) => option.value === answerValue
            );

            if (matchingOption?.color) {
              selectedColor = matchingOption.color;
            }
          });
      }
    }
    console.log(selectedColor);
    selectedColor = selectedColor || "#d1d5db";

    try {
      console.log("post", selectedLayer.id, buildingId);

      const requestBody = {
        buildingAnswers: buildingAnswers,
        color: selectedColor,
        coordinates: coordinates,
        userId: user?.uid,
        projectId: projectId,
        lastModified: new Date().toISOString()
      };
      console.log("Request body:", JSON.stringify(requestBody));

      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL

      const response = await fetch(
        `${API_BASE_URL}/layers/${selectedLayer.id}/buildings/${buildingId}/answers`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Cache-Control": "no-cache",
          },
          body: JSON.stringify(requestBody),
        }
      );

      console.log("Response received:", response);

      if (response.ok) {
        console.log("Data saved successfully");

        setBuildingData((prev) => {
          const existingLayerData = prev[selectedLayer.id] || [];
          const updatedLayerData = [
            ...existingLayerData,
            {
              layerId: selectedLayer.id,
              buildingId: buildingId,
              answers: buildingAnswers,
              coordinates: coordinates,
              color: selectedColor,
            },
          ];
          return { ...prev, [selectedLayer.id]: updatedLayerData };
        });
      } else {
        console.error("Failed to save data, Status:", response.status);
        const errorResponse = await response.json();
        console.error("Error details:", errorResponse);
      }
    } catch (error) {
      console.error("Error saving data:", error);
    }

  
    const isNewBuilding = createdBuildings.some(
      (building) => building.buildingId === buildingId
    );

    if (isNewBuilding) {
     
      const buildingLayerId = `building-layer-${buildingId}`;

      if (map.getLayer(buildingLayerId)) {
        map.setPaintProperty(buildingLayerId, "fill-color", selectedColor);
      }
    } else {
      map.setFeatureState(
        {
          source: "composite",
          sourceLayer: "building",
          id: buildingId,
        },
        { color: selectedColor } 
      );
    }

    setBuildingInfo(null);
  };

  useEffect(() => {
    console.log("buildingData", buildingData);
  }, [buildingData]);

  useEffect(() => {
    if (!map || !selectedLayer || !selectedPoints) return;

    if (!selectedLayer.id.startsWith("layer-form-")) return;

    const handleBuildingClick = (
      e: MapMouseEvent & { point: mapboxgl.Point }
    ) => {
      const features = map.queryRenderedFeatures(e.point, {
        layers: ["building"],
      });

      if (features.length === 0) {
        console.warn("No building features found at clicked location.");
        return;
      }

      const feature = features[0];
      const name = feature.properties?.name || "Unknown";
      const buildingId = feature.id;
      const buildingIdString =
        buildingId !== undefined ? String(buildingId) : "";

      let coordinates: number[] | number[][] | number[][][] = [];

      if (feature.geometry.type === "Point") {
        coordinates = (feature.geometry as GeoJSON.Point).coordinates;
      } else if (feature.geometry.type === "Polygon") {
        coordinates = (feature.geometry as GeoJSON.Polygon).coordinates;
      } else if (feature.geometry.type === "MultiPolygon") {
        // coordinates = (feature.geometry as GeoJSON.MultiPolygon)
        //   .coordinates;
      } else {
        console.warn(`Unsupported geometry type: ${feature.geometry.type}`);
        return;
      }

      let clickedCoordinates: [number, number] = [0, 0];

      if (feature.geometry.type === "Point") {
        clickedCoordinates = (feature.geometry as GeoJSON.Point)
          .coordinates as [number, number];
      } else if (feature.geometry.type === "Polygon") {
        clickedCoordinates = (feature.geometry as GeoJSON.Polygon)
          .coordinates[0][0] as [number, number];
      } else if (feature.geometry.type === "MultiPolygon") {
        clickedCoordinates = (feature.geometry as GeoJSON.MultiPolygon)
          .coordinates[0][0][0] as [number, number];
      } else {
        // console.warn(`Unsupported geometry type: ${feature.geometry.type}`);
        return;
      }

      console.log("Building coordinates:", coordinates);
      const selectedPointscoordinates: [number, number][] = selectedPoints.map(
        (point) => [point.lng, point.lat] as [number, number]
      );
      const isInside = isPointInPolygon(
        clickedCoordinates,
        selectedPointscoordinates
      );
      if (!isInside) {
        console.warn("Clicked building is outside of the selected area.");
        return; 
      }

      map.queryRenderedFeatures({ layers: ["building"] }).forEach((f) => {
        if (f.id !== undefined && f.id !== buildingId) {
          map.setFeatureState(
            {
              source: "composite",
              sourceLayer: "building",
              id: f.id,
            },
            { clicked: false }
          );
        }
      });

      if (buildingId !== undefined) {
        map.setFeatureState(
          {
            source: "composite",
            sourceLayer: "building",
            id: buildingId,
          },
          { clicked: true }
        );
      }

      const layerBuildingData = buildingData[selectedLayer.id] || [];
      const buildingDetails = layerBuildingData.find(
        (building) => String(building.buildingId) === buildingIdString
      );

      if (
        buildingDetails &&
        "questions" in selectedLayer &&
        Array.isArray(selectedLayer.questions)
      ) {
        setAnswers((prev) => ({
          ...prev,
          [buildingIdString]: {
            ...prev[buildingIdString],
            ...buildingDetails.answers,
          },
        }));

        setBuildingInfo({
          name,
          id: buildingIdString,
          coordinates,
          questions: selectedLayer.questions,
        });
      } else if (
        "questions" in selectedLayer &&
        Array.isArray(selectedLayer.questions)
      ) {
        setBuildingInfo({
          name,
          id: buildingIdString,
          coordinates,
          questions: selectedLayer.questions,
        });
      }
    };

    map.on("click", "building", handleBuildingClick);

    return () => {
      map.off("click", "building", handleBuildingClick);
    };
  }, [map, selectedLayer, buildingData, setAnswers]);

  useEffect(() => {
    if (selectedLayer && selectedLayer.id.startsWith("layer-form-")) {
      const layerBuildingData = buildingData[selectedLayer.id] || [];

      layerBuildingData.forEach((building) => {
        if (building.answers) {
          setAnswers((prev) => ({
            ...prev,
            [building.buildingId]: {
              ...prev[building.buildingId],
              ...building.answers, 
            },
          }));
        }
      });
    }
  }, [selectedLayer, buildingData, setAnswers]);

  useEffect(() => {
    if (!map) return;

    map.on("load", () => {
      if (map.getLayer("building")) {
        map.setPaintProperty("building", "fill-color", [
          "case",
          ["to-boolean", ["feature-state", "color"]],
          ["feature-state", "color"], 
          "#D9D3C9", 
        ]);
      }
    });
  }, [map]);

  const updateMapWithBuildingData = async () => {
    console.log("Updating map with visible layers");

    if (!map) return;

    try {
      console.log(layers[0]);
      const targetLayers = layers.filter((layer: Layer) =>
        layer.id.startsWith("layer-form-")
      );

      for (const layer of targetLayers) {
        if (!buildingData[layer.id]) {
          try {
            const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
            const response = await fetch(
            `${API_BASE_URL}/layers/${layer.id}/buildings?userId=${user?.uid}` 
            );

            if (!response.ok) {
              console.error(`Failed to fetch data for layer ${layer.id}`);
              continue;
            }

            const data: BuildingAnswer[] = await response.json();

            setBuildingData((prev) => ({
              ...prev,
              [layer.id]: data,
            }));

            updateLayerFeatures(layer, data); 
          } catch (error) {
            console.error(
              `Error fetching building data for layer ${layer.id}:`,
              error
            );
          }
        } else {
          updateLayerFeatures(layer, buildingData[layer.id]);
        }
      }

      setIsMapInitialized(true);
    } catch (error) {
      console.error("Error updating map with visible layers:", error);
    }
  };

  const updateLayerFeatures = (layer: Layer, data: BuildingAnswer[]) => {
    if (!map) return null;

    data.forEach((building: BuildingAnswer) => {
        const visibleLayers = layers
            .filter(l => l.visible && buildingData[l.id]?.some(b => b.buildingId === building.buildingId))
            .sort((a, b) => a.order - b.order); 

        let colorToApply = "#d1d5db"; 
        if (visibleLayers.length > 0) {
            const topLayer = visibleLayers[0];
            const buildingInfo = buildingData[topLayer.id]?.find(b => b.buildingId === building.buildingId);
            if (buildingInfo) {
                colorToApply = buildingInfo.color;
            }
        }

        if (map.getLayer("building")) {
            map.setFeatureState(
                {
                    source: "composite",
                    sourceLayer: "building",
                    id: building.buildingId,
                },
                { color: colorToApply }
            );
        }
    });

    console.log(
        `Map updated with building data for layer ${layer.id}, visible: ${layer.visible}`
    );
};


  useEffect(() => {
    if (!map || layers.length === 0 || isMapInitialized) return;

    updateMapWithBuildingData();
  }, [map, layers, isMapInitialized]);

  useEffect(() => {
    if (Array.isArray(layers)) {
      layers.forEach((layer) => {
        if (buildingData[layer.id]) {
          updateLayerFeatures(layer, buildingData[layer.id]);
        }
      });
    } else {
      console.error("Layers is not an array:", layers);
    }
  }, [buildingData, layers]);

  const [relationships, setRelationships] = useState<Relationship[]>([]);

  const [selectedRelationship, setSelectedRelationship] =
    useState<Relationship | null>(null); 
  const isDeleteMode = false;
  // const toggleDeleteMode = () => {
  //   setIsDeleteMode((prev) => !prev);
  // };

  const handleRelationshipClick = (event: mapboxgl.MapMouseEvent) => {
    if (isDeleteMode) {
      setRelationshipPoint([]);
      return;
    }

    if (selectedRelationship) {
      setRelationshipPoint([]);
      return;
    }

    if (!selectedLayer || !selectedLayer.id.startsWith("layer-relationship-")) {
      return;
    }

    const lngLat: [number, number] = [event.lngLat.lng, event.lngLat.lat];

    setRelationshipPoint((prevPoints) => {
      let updatedPoints = [...prevPoints, lngLat];

      if (updatedPoints.length === 2) {
        const newRelationship: Relationship = {
          id: `relationship-${Date.now()}`,
          layerId: selectedLayer.id,
          points: updatedPoints,
          description: "Initial description",
          type: "solid",
        };

        setRelationships((prevRelationships) => [
          ...(Array.isArray(prevRelationships) ? prevRelationships : []), 
          newRelationship,
        ]);
        // updatedPoints=[];

        saveRelationshipsToDB(newRelationship);
        updatedPoints = [];

        setRelationshipPoint([]);
      }
      // setRelationshipPoint([]);
      return updatedPoints;
    });
  };
  const handleDeleteRelationship = async (relationshipId: string, description: string, type: "solid" | "double" | "dotted" | "zigzag" | "dashed") => {
    if (!map || !selectedLayer) return;

    const updatedRelationships = relationships.filter(
      (relationship) => relationship.id !== relationshipId
    );

    setRelationships(updatedRelationships);

    const layerId = `${selectedLayer.id}-${relationshipId}`;
    if (map.getSource(layerId)) {
      map.removeLayer(layerId);
      map.removeSource(layerId);
    }

    setSelectedRelationship(null);
    setRelationshipPoint([]);
    try {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      const response = await fetch(
       `${API_BASE_URL}/api/relationships/${relationshipId}`,
        {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            description,
            type,
            userId: user?.uid,
            isDelete: true,
          }),
        }
      );

      if (response.ok) {
        console.log("Relationship updated successfully");
      } else {
        console.error("Failed to update relationship");
      }
    } catch (error) {
      console.error("Error updating relationship:", error);
    }
    // // try {
    // //   // เรียก API เพื่อลบ relationship จากฐานข้อมูล พร้อมส่ง userId
    // //   const response = await fetch(
    // //     `https://geosociomap-backend.onrender.com/api/relationships/${relationshipId}`,
    // //     {
    // //       method: "DELETE",
    // //       headers: {
    // //         "Content-Type": "application/json", // ระบุ Content-Type
    // //       },
    // //       body: JSON.stringify({ userId: user?.uid }), // ส่ง userId ไปใน body
    // //     }
    // //   );

    // //   if (!response.ok) {
    // //     throw new Error("Failed to delete relationship from database");
    // //   }

    // //   // ถ้าลบสำเร็จจากฐานข้อมูล, สามารถทำการแจ้งเตือนหรือทำการอื่น ๆ
    // //   console.log(
    // //     `Relationship ${relationshipId} deleted successfully from database.`
    // //   );
    // } catch (error) {
    //   console.error("Error deleting relationship:", error);
    // }
  };

  useEffect(() => {
    // if (isDeleteMode) {
    //   setRelationshipPoint([]);
    //   return;
    // }

    if (selectedRelationship) {
      setRelationshipPoint([]);
      return;
    }

    if (!selectedLayer || !selectedLayer.id.startsWith("layer-relationship-"))
      return;

    if (map) {
      map.on("click", handleRelationshipClick);
      return () => {
        map.off("click", handleRelationshipClick);
      };
    }
  }, [map, selectedLayer]);

  const handleSavePopup = async (
    description: string,
    type: "solid" | "double" | "dotted" | "zigzag" | "dashed"
  ) => {
    console.log("type", type);
    if (selectedRelationship) {
      setRelationships((prev) =>
        prev.map((r) =>
          r.id === selectedRelationship.id ? { ...r, description, type } : r
        )
      );
      try {
        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
        const response = await fetch(
          `${API_BASE_URL}/api/relationships/${selectedRelationship.id}`,
          {
            method: "PUT",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              description,
              type,
              userId: user?.uid,
              isDelete: false,
              // updatedAt: new Date().toISOString(),
            }),
          }
        );

        if (response.ok) {
          console.log("Relationship updated successfully");
        } else {
          console.error("Failed to update relationship");
        }
      } catch (error) {
        console.error("Error updating relationship:", error);
      }

      setSelectedRelationship(null);
      setRelationshipPoint([]);
    }
  };

  const handleCancelPopup = () => {
    setSelectedRelationship(null);
    setRelationshipPoint([]);
  };

  function generateParallelSolidCoordinates(
    points: [number, number][],
    offset: number = 0.000005 
  ): [number, number][] {
    if (points.length < 2) {
      throw new Error("Invalid input: At least two points are required.");
    }

    const parallelCoordinates: [number, number][] = [];

    for (let i = 0; i < points.length - 1; i++) {
      const [x1, y1] = points[i];
      const [x2, y2] = points[i + 1];

      const dx = x2 - x1;
      const dy = y2 - y1;

      const lineLength = Math.sqrt(dx * dx + dy * dy);

      const normalX = -dy / lineLength; 
      const normalY = dx / lineLength;

      const parallelX1 = x1 + normalX * offset;
      const parallelY1 = y1 + normalY * offset;
      const parallelX2 = x2 + normalX * offset;
      const parallelY2 = y2 + normalY * offset;

      const parallelX3 = x1 - normalX * offset;
      const parallelY3 = y1 - normalY * offset;
      const parallelX4 = x2 - normalX * offset;
      const parallelY4 = y2 - normalY * offset;

      parallelCoordinates.push([parallelX1, parallelY1]);
      parallelCoordinates.push([parallelX2, parallelY2]);
      parallelCoordinates.push([parallelX4, parallelY4]);
      parallelCoordinates.push([parallelX3, parallelY3]);
    }

    return parallelCoordinates;
  }

  function generateDashedCoordinates(
    points: Array<[number, number]>,
    dashLength: number = 0.00001,
    gapLength: number = 0.0001
  ): Array<[number, number]> {
    const dashedCoordinates: Array<[number, number]> = [];

    for (let i = 0; i < points.length - 1; i++) {
      const [startLng, startLat] = points[i];
      const [endLng, endLat] = points[i + 1];

      const segmentLength = Math.sqrt(
        Math.pow(endLng - startLng, 2) + Math.pow(endLat - startLat, 2)
      );
      const numberOfDashes = Math.floor(
        segmentLength / (dashLength + gapLength)
      );

      for (let j = 0; j < numberOfDashes; j++) {
        const ratio = (j * (dashLength + gapLength)) / segmentLength;
        const dashedPoint: [number, number] = [
          startLng + (endLng - startLng) * ratio,
          startLat + (endLat - startLat) * ratio,
        ];

        dashedCoordinates.push(dashedPoint);

        const skipRatio =
          ((j + 0.5) * (dashLength + gapLength)) / segmentLength;
        const skippedPoint: [number, number] = [
          startLng + (endLng - startLng) * skipRatio,
          startLat + (endLat - startLat) * skipRatio,
        ];

        dashedCoordinates.push(skippedPoint);
      }
    }

    return dashedCoordinates;
  }

  useEffect(() => {
    if (!map || !selectedLayer) return;

    if (isDeleteMode) {
      setRelationshipPoint([]);
      return;
    }

    if (!selectedLayer.id.startsWith("layer-relationship-")) return;

    const validRelationships = Array.isArray(relationships)
      ? relationships
      : [];

    const relationshipsByLayer = validRelationships.reduce(
      (acc, relationship) => {
        if (!acc[relationship.layerId]) {
          acc[relationship.layerId] = [];
        }
        acc[relationship.layerId].push(relationship);
        return acc;
      },
      {} as Record<string, Relationship[]>
    );

    Object.keys(relationshipsByLayer).forEach((layerId) => {
      const layerRelationships = relationshipsByLayer[layerId];

      const dashedRelationships = layerRelationships.filter(
        (relationship) => relationship.type === "dashed"
      );

      const solidRelationships = layerRelationships.filter(
        (relationship) => relationship.type === "solid"
      );

      const zigzagRelationships = layerRelationships.filter(
        (relationship) => relationship.type === "zigzag"
      );

      const doubleRelationships = layerRelationships.filter(
        (relationship) => relationship.type === "double"
      );


      doubleRelationships.forEach((relationship) => {
        if (map.getLayer(`${layerId}-${relationship.id}`)) {
          map.removeLayer(`${layerId}-${relationship.id}`);
        }
        if (map.getSource(`${layerId}-${relationship.id}`)) {
          map.removeSource(`${layerId}-${relationship.id}`);
        }

        if (!map.getSource(`${layerId}-${relationship.id}`)) {
          map.addSource(`${layerId}-${relationship.id}`, {
            type: "geojson",
            data: {
              type: "FeatureCollection",
              features: [
                {
                  type: "Feature",
                  geometry: {
                    type: "LineString",
                    coordinates: relationship.points,
                  },
                  properties: {
                    relationshipId: relationship.id,
                    type: relationship.type,
                  },
                },
              ],
            },
          });
        }

        if (!map.getLayer(`${layerId}-${relationship.id}`)) {
          map.addLayer({
            id: `${layerId}-${relationship.id}`, 
            type: "line",
            source: `${layerId}-${relationship.id}`,
            layout: {
              visibility: layers.find((layer) => layer.id === layerId)?.visible
                ? "visible"
                : "none", 
            },
            paint: {
              "line-color": "#3b82f6",
              "line-width": 2,
              "line-gap-width": 2, 
            },
          });
        }
        map.on("click", `${layerId}-${relationship.id}`, (e) => {
          const features = map.queryRenderedFeatures(e.point, {
            layers: [`${layerId}-${relationship.id}`],
          });

          if (!features.length) return;

          const feature = features[0];
          const relationshipId = feature.properties?.relationshipId;

          const clickedRelationship = relationships.find(
            (relationship) => relationship.id === relationshipId
          );

          if (clickedRelationship) {
            setSelectedRelationship(clickedRelationship);
            setRelationshipPoint([]);
          } else {
            const point = e.lngLat;
            const tolerance = 0.1;

            const nearbyRelationship = relationships.find((relationship) =>
              relationship.points.some((p) => {
                const dist = Math.sqrt(
                  Math.pow(p[0] - point.lng, 2) + Math.pow(p[1] - point.lat, 2)
                );
                return dist <= tolerance;
              })
            );

            if (nearbyRelationship) {
              setSelectedRelationship(nearbyRelationship);
              setRelationshipPoint([]);
            }
          }
        });
      });

      dashedRelationships.forEach((relationship) => {
        if (map.getLayer(`${layerId}-${relationship.id}`)) {
          map.removeLayer(`${layerId}-${relationship.id}`);
        }
        if (map.getSource(`${layerId}-${relationship.id}`)) {
          map.removeSource(`${layerId}-${relationship.id}`);
        }

        if (!map.getSource(`${layerId}-${relationship.id}`)) {
          map.addSource(`${layerId}-${relationship.id}`, {
            type: "geojson",
            data: {
              type: "FeatureCollection",
              features: [
                {
                  type: "Feature",
                  geometry: {
                    type: "LineString",
                    coordinates:
                      relationship.type === "zigzag"
                        ? generateZigzagCoordinates(
                            relationship.points,
                            0.00001,
                            12
                          )
                        : relationship.type === "double"
                        ? generateParallelSolidCoordinates(relationship.points)
                        : relationship.type === "dashed"
                        ? generateDashedCoordinates(relationship.points)
                        : relationship.points,
                  },
                  properties: {
                    relationshipId: relationship.id,
                    type: relationship.type,
                  },
                },
              ],
            },
          });
        }

        if (!map.getLayer(`${layerId}-${relationship.id}`)) {
          map.addLayer({
            id: `${layerId}-${relationship.id}`,
            type: "line",
            source: `${layerId}-${relationship.id}`, 
            layout: {
              visibility: layers.find((layer) => layer.id === layerId)?.visible
                ? "visible"
                : "none",
            },
            paint: {
              "line-color": "#3b82f6",
              "line-width": 2,
              "line-dasharray": [10, 5],
            },
          });
        }
        map.on("click", `${layerId}-${relationship.id}`, (e) => {
          const features = map.queryRenderedFeatures(e.point, {
            layers: [`${layerId}-${relationship.id}`],
          });

          if (!features.length) return;

          const feature = features[0];
          const relationshipId = feature.properties?.relationshipId;

          const clickedRelationship = relationships.find(
            (relationship) => relationship.id === relationshipId
          );

          if (clickedRelationship) {
            setSelectedRelationship(clickedRelationship);
            setRelationshipPoint([]);
          } else {
            const point = e.lngLat;
            const tolerance = 0.1;

            const nearbyRelationship = relationships.find((relationship) =>
              relationship.points.some((p) => {
                const dist = Math.sqrt(
                  Math.pow(p[0] - point.lng, 2) + Math.pow(p[1] - point.lat, 2)
                );
                return dist <= tolerance;
              })
            );

            if (nearbyRelationship) {
              setSelectedRelationship(nearbyRelationship);
              setRelationshipPoint([]);
            }
          }
        });
      });

      zigzagRelationships.forEach((relationship) => {
        if (map.getLayer(`${layerId}-${relationship.id}`)) {
          map.removeLayer(`${layerId}-${relationship.id}`);
        }
        if (map.getSource(`${layerId}-${relationship.id}`)) {
          map.removeSource(`${layerId}-${relationship.id}`);
        }

        if (!map.getSource(`${layerId}-${relationship.id}`)) {
          map.addSource(`${layerId}-${relationship.id}`, {
            type: "geojson",
            data: {
              type: "FeatureCollection",
              features: [
                {
                  type: "Feature",
                  geometry: {
                    type: "LineString",
                    coordinates:
                      relationship.type === "zigzag"
                        ? generateZigzagCoordinates(
                            relationship.points,
                            0.00001,
                            12
                          )
                        : relationship.type === "double"
                        ? generateParallelSolidCoordinates(relationship.points)
                        : relationship.type === "dashed"
                        ? generateDashedCoordinates(relationship.points)
                        : relationship.points,
                  },
                  properties: {
                    relationshipId: relationship.id,
                    type: relationship.type,
                  },
                },
              ],
            },
          });
        }

        if (!map.getLayer(`${layerId}-${relationship.id}`)) {
          map.addLayer({
            id: `${layerId}-${relationship.id}`, 
            type: "line",
            source: `${layerId}-${relationship.id}`, 
            layout: {
              visibility: layers.find((layer) => layer.id === layerId)?.visible
                ? "visible"
                : "none",
            },
            paint: {
              "line-color": "#3b82f6",
              "line-width": 2,
              "line-dasharray": [],
            },
          });
        }
        map.on("click", `${layerId}-${relationship.id}`, (e) => {
          const features = map.queryRenderedFeatures(e.point, {
            layers: [`${layerId}-${relationship.id}`],
          });

          if (!features.length) return;

          const feature = features[0];
          const relationshipId = feature.properties?.relationshipId;

          const clickedRelationship = relationships.find(
            (relationship) => relationship.id === relationshipId
          );

          if (clickedRelationship) {
            setSelectedRelationship(clickedRelationship);
            setRelationshipPoint([]);
          } else {
            const point = e.lngLat;
            const tolerance = 0.1;

            const nearbyRelationship = relationships.find((relationship) =>
              relationship.points.some((p) => {
                const dist = Math.sqrt(
                  Math.pow(p[0] - point.lng, 2) + Math.pow(p[1] - point.lat, 2)
                );
                return dist <= tolerance;
              })
            );

            if (nearbyRelationship) {
              setSelectedRelationship(nearbyRelationship);
              setRelationshipPoint([]);
            }
          }
        });
      });

      solidRelationships.forEach((relationship) => {
        if (map.getLayer(`${layerId}-${relationship.id}`)) {
          map.removeLayer(`${layerId}-${relationship.id}`);
        }
        if (map.getSource(`${layerId}-${relationship.id}`)) {
          map.removeSource(`${layerId}-${relationship.id}`);
        }

        if (!map.getSource(`${layerId}-${relationship.id}`)) {
          map.addSource(`${layerId}-${relationship.id}`, {
            type: "geojson",
            data: {
              type: "FeatureCollection",
              features: [
                {
                  type: "Feature",
                  geometry: {
                    type: "LineString",
                    coordinates: relationship.points,
                  },
                  properties: {
                    relationshipId: relationship.id,
                    type: relationship.type,
                  },
                },
              ],
            },
          });
        }

        if (!map.getLayer(`${layerId}-${relationship.id}`)) {
          map.addLayer({
            id: `${layerId}-${relationship.id}`, 
            type: "line",
            source: `${layerId}-${relationship.id}`,
            layout: {
              visibility: layers.find((layer) => layer.id === layerId)?.visible
                ? "visible"
                : "none", 
            },
            paint: {
              "line-color": "#3b82f6",
              "line-width": 2,
              "line-dasharray": [],
            },
          });
        }

        map.on("click", `${layerId}-${relationship.id}`, (e) => {
          const features = map.queryRenderedFeatures(e.point, {
            layers: [`${layerId}-${relationship.id}`],
          });

          if (!features.length) return;

          const feature = features[0];
          const relationshipId = feature.properties?.relationshipId;

          const clickedRelationship = relationships.find(
            (relationship) => relationship.id === relationshipId
          );

          if (clickedRelationship) {
            setSelectedRelationship(clickedRelationship);
            setRelationshipPoint([]);
          } else {
            const point = e.lngLat;
            const tolerance = 0.1;

            const nearbyRelationship = relationships.find((relationship) =>
              relationship.points.some((p) => {
                const dist = Math.sqrt(
                  Math.pow(p[0] - point.lng, 2) + Math.pow(p[1] - point.lat, 2)
                );
                return dist <= tolerance;
              })
            );

            if (nearbyRelationship) {
              setSelectedRelationship(nearbyRelationship);
              setRelationshipPoint([]);
            }
          }
        });
      });
    });
  }, [relationships, map]);

  const toggleRelationshipVisibility = (
    layerId: string,
    relationships: Relationship[],
    isVisible: boolean
  ) => {
    if (map) {
      const filteredRelationships = relationships.filter(
        (relationship) => relationship.layerId === layerId
      );

      const dashedRelationships = filteredRelationships.filter(
        (relationship) => relationship.type === "dashed"
      );

      const solidRelationships = filteredRelationships.filter(
        (relationship) => relationship.type === "solid"
      );

      const zigzagRelationships = filteredRelationships.filter(
        (relationship) => relationship.type === "zigzag"
      );

      const doubleRelationships = filteredRelationships.filter(
        (relationship) => relationship.type === "double"
      );

      doubleRelationships.forEach((relationship) => {
        const layer = map.getLayer(`${layerId}-${relationship.id}`);

        if (layer) {
          const visibility = isVisible ? "visible" : "none";
          map.setLayoutProperty(
            `${layerId}-${relationship.id}`,
            "visibility",
            visibility
          );
        } else {
          if (!map.getSource(`${layerId}-${relationship.id}`)) {
            map.addSource(`${layerId}-${relationship.id}`, {
              type: "geojson",
              data: {
                type: "FeatureCollection",
                features: [
                  {
                    type: "Feature",
                    geometry: {
                      type: "LineString",
                      coordinates: relationship.points,
                    },
                    properties: {
                      relationshipId: relationship.id,
                      type: relationship.type,
                    },
                  },
                ],
              },
            });
          }

          if (!map.getLayer(`${layerId}-${relationship.id}`)) {
            map.addLayer({
              id: `${layerId}-${relationship.id}`, 
              type: "line",
              source: `${layerId}-${relationship.id}`, 
              layout: {
                visibility: layers.find((layer) => layer.id === layerId)
                  ?.visible
                  ? "visible"
                  : "none",
              },
              paint: {
                "line-color": "#3b82f6",
                "line-width": 2,
                "line-gap-width": 2, 
              },
            });
          }
        }
      });

      dashedRelationships.forEach((relationship) => {
        const layer = map.getLayer(`${layerId}-${relationship.id}`);

        if (layer) {
          const visibility = isVisible ? "visible" : "none";
          map.setLayoutProperty(
            `${layerId}-${relationship.id}`,
            "visibility",
            visibility
          );
        } else {
          if (!map.getSource(`${layerId}-${relationship.id}`)) {
            map.addSource(`${layerId}-${relationship.id}`, {
              type: "geojson",
              data: {
                type: "FeatureCollection",
                features: [
                  {
                    type: "Feature",
                    geometry: {
                      type: "LineString",
                      coordinates:
                        relationship.type === "zigzag"
                          ? generateZigzagCoordinates(
                              relationship.points,
                              0.00001,
                              12
                            )
                          : relationship.type === "double"
                          ? generateParallelSolidCoordinates(
                              relationship.points
                            )
                          : relationship.type === "dashed"
                          ? generateDashedCoordinates(relationship.points)
                          : relationship.points,
                    },
                    properties: {
                      relationshipId: relationship.id,
                      type: relationship.type,
                    },
                  },
                ],
              },
            });
          }

          if (!map.getLayer(`${layerId}-${relationship.id}`)) {
            map.addLayer({
              id: `${layerId}-${relationship.id}`, 
              type: "line",
              source: `${layerId}-${relationship.id}`, 
              layout: {
                visibility: layers.find((layer) => layer.id === layerId)
                  ?.visible
                  ? "visible"
                  : "none", 
              },
              paint: {
                "line-color": "#3b82f6",
                "line-width": 2,
                "line-dasharray": [10, 5], 
              },
            });
          }
        }
      });

      zigzagRelationships.forEach((relationship) => {
        const layer = map.getLayer(`${layerId}-${relationship.id}`);

        if (layer) {
          const visibility = isVisible ? "visible" : "none";
          map.setLayoutProperty(
            `${layerId}-${relationship.id}`,
            "visibility",
            visibility
          );
        } else {
          if (!map.getSource(`${layerId}-${relationship.id}`)) {
            map.addSource(`${layerId}-${relationship.id}`, {
              type: "geojson",
              data: {
                type: "FeatureCollection",
                features: [
                  {
                    type: "Feature",
                    geometry: {
                      type: "LineString",
                      coordinates:
                        relationship.type === "zigzag"
                          ? generateZigzagCoordinates(
                              relationship.points,
                              0.00001,
                              12
                            )
                          : relationship.type === "double"
                          ? generateParallelSolidCoordinates(
                              relationship.points
                            )
                          : relationship.type === "dashed"
                          ? generateDashedCoordinates(relationship.points)
                          : relationship.points,
                    },
                    properties: {
                      relationshipId: relationship.id,
                      type: relationship.type,
                    },
                  },
                ],
              },
            });
            const visibility = isVisible ? "visible" : "none";
            map.setLayoutProperty(
              `${layerId}-${relationship.id}`,
              "visibility",
              visibility
            );
          }
        }
      });

      solidRelationships.forEach((relationship) => {
        const layer = map.getLayer(`${layerId}-${relationship.id}`);

        if (layer) {
          const visibility = isVisible ? "visible" : "none";
          map.setLayoutProperty(
            `${layerId}-${relationship.id}`,
            "visibility",
            visibility
          );
        } else {

          if (!map.getSource(`${layerId}-${relationship.id}`)) {
            map.addSource(`${layerId}-${relationship.id}`, {
              type: "geojson",
              data: {
                type: "FeatureCollection",
                features: [
                  {
                    type: "Feature",
                    geometry: {
                      type: "LineString",
                      coordinates: relationship.points,
                    },
                    properties: {
                      relationshipId: relationship.id,
                      type: relationship.type,
                    },
                  },
                ],
              },
            });
          }

          if (!map.getLayer(`${layerId}-${relationship.id}`)) {
            map.addLayer({
              id: `${layerId}-${relationship.id}`,
              type: "line",
              source: `${layerId}-${relationship.id}`, 
              layout: {
                visibility: layers.find((layer) => layer.id === layerId)
                  ?.visible
                  ? "visible"
                  : "none", 
              },
              paint: {
                "line-color": "#3b82f6",
                "line-width": 2,
                "line-dasharray": [], 
              },
            });
          }

          const visibility = isVisible ? "visible" : "none";
          map.setLayoutProperty(
            `${layerId}-${relationship.id}`,
            "visibility",
            visibility
          );
        }
      });
    }
  };

  useEffect(() => {
    if (!map || !Array.isArray(layers) || layers.length === 0) return;

    layers.forEach((layer) => {
      if (
        layer &&
        typeof toggleRelationshipVisibility === "function" &&
        layer.id.startsWith("layer-relationship-")
      ) {
        toggleRelationshipVisibility(layer.id, relationships, layer.visible);
      }
    });
  }, [selectedLayer?.visible]); 

  useEffect(() => {
    if (!projectId || !user?.uid) {
      console.error("Missing projectId or userId");
      return;
    }
    const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL

    fetch(
      `${API_BASE_URL}/api/relationships?projectId=${projectId}&userId=${user?.uid}`
    )
      .then((res) => {
        if (!res.ok) {
          throw new Error("Failed to fetch relationships");
        }
        return res.json();
      })
      .then((data) => {
        console.log("Fetched relationships:", data);
        setRelationships(data); 
      })
      .catch((error) => {
        console.error("Error fetching relationships:", error);
      });
  }, [projectId, user?.uid]);

  function generateZigzagCoordinates(
    points: [number, number][],
    amplitude: number,
    frequency: number
  ): [number, number][] {
    const zigzagCoordinates: [number, number][] = [];

    for (let i = 0; i < points.length - 1; i++) {
      const start = points[i];
      const end = points[i + 1];

      const dx = end[0] - start[0];
      const dy = end[1] - start[1];
      // const lineLength = Math.sqrt(dx * dx + dy * dy);

      const angle = Math.atan2(dy, dx); 

      // const perpX = -dy / lineLength; 
      // const perpY = dx / lineLength;

      const stepX = dx / frequency;
      const stepY = dy / frequency;

      for (let j = 0; j <= frequency; j++) {
        const x = start[0] + stepX * j;
        const y = start[1] + stepY * j;

        const zigzagX =
          x +
          amplitude * Math.cos(angle + Math.PI / 2) * (j % 2 === 0 ? 1 : -1);
        const zigzagY =
          y +
          amplitude * Math.sin(angle + Math.PI / 2) * (j % 2 === 0 ? 1 : -1);
        zigzagCoordinates.push([zigzagX, zigzagY]);
      }
    }

    return zigzagCoordinates;
  }

  const saveRelationshipsToDB = async (newRelationship: Relationship) => {
    console.log("newRelationship", newRelationship);

    if (
      !newRelationship.layerId ||
      !newRelationship.points ||
      !Array.isArray(newRelationship.points) ||
      newRelationship.points.length === 0
    ) {
      console.error(
        "layerId and points are required, and points must be a non-empty array"
      );
      return;
    }

    const relationshipWithUser = {
      ...newRelationship,
      userId: user?.uid, 
      projectId: projectId,
      isDelete: false,
      updatedAt: new Date().toISOString(),
    };

    try {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      const response = await fetch(
        `${API_BASE_URL}/api/relationships`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(relationshipWithUser), 
        }
      );
      console.log("response");
      console.log(response);
      // if (!response.ok) {
      //   throw new Error("Failed to save relationship");
      // }
      // setSelectedRelationship(null);
      setRelationshipPoint([]);
      console.log("Relationship saved successfully");
    } catch (error) {
      console.error("Error saving relationship:", error);
    }
  };

  useEffect(() => {
    if (!map || !selectedOptions || !selectedLayerData?.data) {
      console.warn("Map or Data not available");
      return;
    }
  
    const handleMapLoad = () => {
      try {
        if (map.getLayer("density-layer")) {
          map.removeLayer("density-layer");
        }
        if (map.getSource("density-source")) {
          map.removeSource("density-source");
        }
  
        console.log("selectedOptions", selectedOptions);
        console.log("selectedLayerData", selectedLayerData);
  
        if (!Array.isArray(selectedLayerData.data) || selectedLayerData.data.length === 0) {
          console.warn("No data available for heatmap.");
          return;
        }
  
        const features: GeoJSON.Feature<GeoJSON.Point>[] = selectedLayerData.data
        .map((data) => {
          const coordinates = getCoordinatesForBuilding(data.buildingId, selectedLayerData);
          
          if (!coordinates || coordinates.length < 2) {
            console.warn(`Invalid coordinates for buildingId: ${data.buildingId}`);
            return null;
          }
      
          const center: number[] = getPolygonCenter(coordinates);
          if (!center || center.length !== 2) {
            console.warn(`Invalid center coordinates for buildingId: ${data.buildingId}`);
            return null;
          }
      
          const count = Object.entries(selectedOptions).reduce((acc, [questionId, values]) => {
            const answer = data.answers?.[questionId];
      
            if (Array.isArray(answer)) {
              return acc + answer.filter((ans) => values.includes(ans)).length;
            } else if (values.includes(String(answer))) {
              return acc + 1;
            }
            return acc;
          }, 0);
      
          return {
            type: "Feature",
            geometry: { type: "Point", coordinates: center },
            properties: {
              buildingId: data.buildingId,
              count: count,
            },
          };
        })
        .filter((feature) => feature !== null) as GeoJSON.Feature<GeoJSON.Point>[];
  
        if (features.length === 0) {
          console.warn("No valid features for heatmap.");
          return;
        }
  
        const geojsonData: GeoJSON.FeatureCollection<GeoJSON.Point> = {
          type: "FeatureCollection",
          features,
        };
  
        map.addSource("density-source", {
          type: "geojson",
          data: geojsonData,
        });
  
        map.addLayer({
          id: "density-layer",
          type: "heatmap",
          source: "density-source",
          paint: {
            "heatmap-weight": [
              "interpolate",
              ["linear"],
              ["get", "count"],
              0,
              0,
              10,
              1,
            ],
            "heatmap-intensity": 5,
            "heatmap-radius": 30,
            "heatmap-color": [
              "interpolate",
              ["linear"],
              ["heatmap-density"],
              0,
              "rgba(33,102,172,0)",
              0.2,
              "rgb(103,169,207)",
              0.4,
              "rgb(209,229,240)",
              0.6,
              "rgb(253,219,199)",
              0.8,
              "rgb(239,138,98)",
              1,
              "rgb(178,24,43)",
            ],
          },
        });
  
      } catch (error) {
        console.error("Error in handleMapLoad:", error);
      }
    };
  
    if (!map.isStyleLoaded()) {
      map.on("load", handleMapLoad);
    } else {
      handleMapLoad();
    }
  
    return () => {
      if (map) {
        map.off("load", handleMapLoad);
      }
    };
  }, [map, selectedOptions, selectedLayerData]);
  

  const getCoordinatesForBuilding = (
    buildingId: string,
    selectedLayerData: SelectedLayerData
  ): number[][] | undefined => {
    const building = selectedLayerData.data.find(
      (data: LayerData) => data.buildingId === buildingId
    );
  
    if (building?.coordinates && Array.isArray(building.coordinates) && building.coordinates.length > 0) {
      const extractedCoordinates = building.coordinates[0]; 
      if (Array.isArray(extractedCoordinates) && extractedCoordinates.length > 0) {
        return extractedCoordinates;
      }
    }
  
    console.warn(`Invalid coordinates for buildingId: ${buildingId}`);
    return undefined; 
  };

  const getPolygonCenter = (coordinates: number[][] | undefined): number[] => {
    if (!coordinates || coordinates.length === 0) {
      console.warn("Invalid coordinates array");
      return [0, 0]; 
    }
  
    let sumLng = 0;
    let sumLat = 0;
  
    coordinates.forEach(([lng, lat]) => {
      sumLng += lng;
      sumLat += lat;
    });
  
    return [sumLng / coordinates.length, sumLat / coordinates.length];
  };
  // const [buildingCoordinates, setBuildingCoordinates] = useState<
  //   [number, number][]
  // >([]);
  // const getPolygonCenter = (coordinates: number[][]) => {
  //   let sumLng = 0;
  //   let sumLat = 0;
  
  //   coordinates.forEach(([lng, lat]) => {
  //     sumLng += lng;
  //     sumLat += lat;
  //   });
  
  //   return [sumLng / coordinates.length, sumLat / coordinates.length];
  // };

  const [createdBuildings, setCreatedBuildings] = useState<
    { buildingId: string; layerId: string }[]
  >([]);
  const buildingCoordinatesRef = useRef<[number, number][]>([]);
  // const [createdBuildingMarkers, setCreatedBuildingMarkers] = useState<
  //   mapboxgl.Marker[]
  // >([]); // State to store markers

  const removeBuilding = (buildingId: string) => {
    if (!map) return;

    const buildingToRemove = createdBuildings.find(
      (building) => building.buildingId === buildingId
    );

    if (buildingToRemove) {
      const { layerId } = buildingToRemove;

      if (map.getLayer(layerId)) {
        map.removeLayer(layerId);
      }
      if (map.getSource(layerId)) {
        map.removeSource(layerId);
      }

      setCreatedBuildings((prev) =>
        prev.filter((building) => building.buildingId !== buildingId)
      );
    }
  };

  const [textInfo, setTextInfo] = useState<TextInfo[]>([]);

  const [tempInfo, setTempInfo] = useState<{
    coordinates: [number, number];
    description: string;
  }>({
    coordinates: [0, 0],
    description: "",
  });

  useEffect(() => {
    async function fetchData() {
      if (!projectId || !user?.uid) {
        console.log("projectId or userId is missing");
        return; 
      }
      try {
        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
        const response = await fetch(
          `${API_BASE_URL}/textbuilding/data?projectId=${projectId}&userId=${user?.uid}`
        );
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        setTextInfo(
          data.map((item: TextInfo) => ({
            coordinates: item.coordinates as [number, number],
            description: item.description as string,
          }))
        );
      } catch (error) {
        console.error("Failed to fetch data:", error);
      }
    }

    fetchData();
  }, [projectId, user?.uid]);

  const handlesavetext = async (newDescription: string) => {
    if (map == null) return;

    console.log(newDescription);

    const body = {
      userId: user?.uid,
      projectId,
      coordinates: tempInfo.coordinates,
      description: newDescription,
    };

    try {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      const response = await fetch(
        `${API_BASE_URL}/textbuilding/save`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        }
      );
      const data = await response.json();

      if (response.ok) {
        console.log("Data saved to MongoDB:", data);
        setTextInfo((prevTextInfo) => {
          const updatedTextInfo = [...prevTextInfo];
          const index = updatedTextInfo.findIndex(
            (info) =>
              Math.abs(info.coordinates[0] - tempInfo.coordinates[0]) <
                0.0001 &&
              Math.abs(info.coordinates[1] - tempInfo.coordinates[1]) < 0.0001
          );

          if (index !== -1) {
            updatedTextInfo[index].description = newDescription;
          } else {
            updatedTextInfo.push({
              coordinates: tempInfo.coordinates,
              description: newDescription,
            });
          }
          return updatedTextInfo;
        });

        setTempInfo({ coordinates: [0, 0], description: "" });
        setTimeout(() => {
          closePopup();
        }, 100);
      } else {
        console.error("Failed to save data:", data.message);
      }
    } catch (error) {
      console.error("Error saving data to backend:", error);
    }
  };

  useEffect(() => {
    if (!map) return;
    console.log(textInfo);
    const places: GeoJSON.FeatureCollection = {
      type: "FeatureCollection",
      features: textInfo.map((info) => ({
        type: "Feature",
        properties: { description: info.description },
        geometry: { type: "Point", coordinates: info.coordinates },
      })),
    };

    if (map.getLayer("poi-labels")) {
      map.removeLayer("poi-labels");
    }
    if (map.getSource("places")) {
      map.removeSource("places");
    }

    if (map.isStyleLoaded()) {
      map.addSource("places", {
        type: "geojson",
        data: places,
      });

      map.addLayer({
        id: "poi-labels",
        type: "symbol",
        source: "places",
        layout: {
          "text-field": ["get", "description"],
          "text-size": 18,
          "text-anchor": "top",
          "text-justify": "center",
        },
        paint: {
          "text-color": "#007bff",
          "text-halo-color": "#ffffff",
          "text-halo-width": 2,
        },
      });

      console.log("Updated Map with new textInfo:", textInfo);
    }
  }, [textInfo, map]);

  useEffect(() => {
    if (!map) return;

    const handleMapClick = (event: mapboxgl.MapMouseEvent) => {
      if (isCreatingBuilding) {
        if (selectedMode === "Delete") {
          handleDeleteMode(event);
          return;
        }

        if (selectedMode === "Add") {
          handleAddMode(event);
        }

        if (selectedMode === "Text") {
          console.log("pass");
          handleTextMode(event);
        }

        if (selectedMode === "DeleteText") {
          console.log("pass");
          handleTextDeleteMode(event);
        }
      } else {
        handleSelectBuilding(event);
      }
    };

    const handleDeleteMode = async (event: mapboxgl.MapMouseEvent) => {
      const features = map.queryRenderedFeatures(event.point, {
        layers: createdBuildings.map((building) => building.layerId),
      });

      if (features.length > 0) {
        const buildingId = features[0].properties?.buildingId;
        if (buildingId) {
          removeBuilding(buildingId);
          try {
            const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
            const response = await fetch(
             `${API_BASE_URL}/api/deleteBuilding`,
              {
                method: "DELETE",
                headers: {
                  "Content-Type": "application/json",
                },
                body: JSON.stringify({ buildingId }),
              }
            );

            if (response.ok) {
              console.log(
                `Building ${buildingId} deleted successfully from database.`
              );
            } else {
              const errorData = await response.json();
              console.error(
                `Failed to delete building ${buildingId}. Error: ${errorData.message}`
              );
            }
          } catch (error) {
            console.error(
              `Error deleting building ${buildingId} from database:`,
              error
            );
          }
        }
      }
    };

    const handleAddMode = (event: mapboxgl.MapMouseEvent) => {
      const lngLat: [number, number] = [event.lngLat.lng, event.lngLat.lat];
      buildingCoordinatesRef.current.push(lngLat);

      if (buildingCoordinatesRef.current.length === 4) {
        createBuilding(buildingCoordinatesRef.current);
        buildingCoordinatesRef.current = []; 
      } else {
        updateBuildingOutline(buildingCoordinatesRef.current); 
      }
    };

    const handleSelectBuilding = (event: mapboxgl.MapMouseEvent) => {
      if (!selectedLayer || !("questions" in selectedLayer)) return;

      for (const building of createdBuildings) {
        const features = map.queryRenderedFeatures(event.point, {
          layers: [building.layerId],
        });

        if (features.length > 0) {
          const feature = features[0];
          const buildingIdString = feature.properties?.buildingId;
          const geometry = feature.geometry;

          if (geometry.type === "Polygon" || geometry.type === "MultiPolygon") {
            const clickedCoordinate: [number, number] = [
              event.lngLat.lng,
              event.lngLat.lat,
            ];

            if (buildingIdString) {
              setBuildingInfo({
                name: feature.properties?.name || "Unnamed Building",
                id: buildingIdString,
                coordinates: clickedCoordinate,
                questions: selectedLayer.questions,
              });
            }
          }
        }
      }
    };

    const handleTextMode = (event: mapboxgl.MapMouseEvent) => {
      const clickedCoordinate: [number, number] = [
        event.lngLat.lng,
        event.lngLat.lat,
      ];

      const tolerance = 0.000001;

      const existingInfo = textInfo.find(
        (info) =>
          Math.abs(info.coordinates[0] - clickedCoordinate[0]) < tolerance &&
          Math.abs(info.coordinates[1] - clickedCoordinate[1]) < tolerance
      );

      if (existingInfo) {
        setTempInfo(existingInfo);
      } else {
        setTempInfo({ coordinates: clickedCoordinate, description: "" });
      }

      setShowPopup(true);
      console.log("Clicked at coordinates:", clickedCoordinate);
    };

    const handleTextDeleteMode = async (event: mapboxgl.MapMouseEvent) => {
      const clickedCoordinate = [event.lngLat.lng, event.lngLat.lat];

      const tolerance = 0.0001;
      const existingInfoIndex = textInfo.findIndex(
        (info) =>
          Math.abs(info.coordinates[0] - clickedCoordinate[0]) < tolerance &&
          Math.abs(info.coordinates[1] - clickedCoordinate[1]) < tolerance
      );

      if (existingInfoIndex !== -1) {
        const coordinates = textInfo[existingInfoIndex].coordinates;

        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
        try {
          const response = await fetch(
           `${API_BASE_URL}/textbuilding/delete`,
            {
              method: "DELETE",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                userId: user?.uid,
                projectId,
                coordinates,
              }),
            }
          );
          const data = await response.json();

          if (response.ok) {
            console.log("Data deleted:", data);
            setTextInfo((prevTextInfo) =>
              prevTextInfo.filter((_, index) => index !== existingInfoIndex)
            );
          } else {
            console.error("Failed to delete data:", data.message);
          }
        } catch (error) {
          console.error("Error deleting data:", error);
        }
      } else {
        console.log(
          "No info found to delete at coordinates:",
          clickedCoordinate
        );
      }
    };

    map.on("click", handleMapClick);

    return () => {
      map.off("click", handleMapClick);
    };
  }, [
    map,
    isCreatingBuilding,
    selectedLayer,
    selectedMode,
    createdBuildings,
    textInfo,
  ]);

  useEffect(() => {
    console.log(textInfo);
  }, [textInfo]);

  useEffect(() => {
    if (!map || !map.getCanvas()) return;

    const updateCursor = () => {
      if (selectedMode === "Add") {
        map.getCanvas().style.cursor = "copy"; 
      } else if (selectedLayer?.id.startsWith("layer-symbol-")) {
        map.getCanvas().style.cursor = "copy";
      } else {
        map.getCanvas().style.cursor = "default"; 
      }
    };

    updateCursor();

    return () => {
      if (map && map.getCanvas()) {
        map.getCanvas().style.cursor = "default"; 
      }
    };
  }, [selectedMode, selectedLayer, map]); 

  const updateBuildingOutline = (coordinates: [number, number][]) => {
    if (coordinates.length < 2) return;
    if (!map) return;

    const outlineGeoJSON: GeoJSON.FeatureCollection = {
      type: "FeatureCollection",
      features: [
        {
          type: "Feature",
          geometry: {
            type: "Polygon", 
            coordinates: [coordinates.concat([coordinates[0]])], 
          },
          properties: {
            name: "Building Outline",
          },
        },
      ],
    };

    const layerId = `outline-${Date.now()}`;
    if (map.getLayer(layerId)) {
      map.removeLayer(layerId);
      map.removeSource(layerId);
    }

    map.addSource(layerId, {
      type: "geojson",
      data: outlineGeoJSON,
    });

    map.addLayer({
      id: layerId,
      type: "line", 
      source: layerId,
      paint: {
        "line-color": "#D9D3C9", 
        "line-width": 2,
        "line-opacity": 0.7,
      },
    });
  };

  const createBuilding = (coordinates: [number, number][]) => {
    if (coordinates.length !== 4) return;
    if (!map) return;

    const buildingId = `building-${Date.now()}`;

    const buildingGeoJSON: GeoJSON.FeatureCollection = {
      type: "FeatureCollection",
      features: [
        {
          type: "Feature",
          geometry: {
            type: "Polygon",
            coordinates: [coordinates],
          },
          properties: {
            name: "New Building",
            description: "User created building",
            buildingId, 
          },
        },
      ],
    };

    const layerId = `building-layer-${buildingId}`;

    map.addSource(layerId, {
      type: "geojson",
      data: buildingGeoJSON,
    });

    map.addLayer({
      id: layerId,
      type: "fill",
      source: layerId,
      paint: {
        "fill-color": "#D9D3C9",
        // "fill-opacity": 0.5,
      },
    });

    saveBuildingToDatabase(coordinates, buildingId);

    setCreatedBuildings((prev) => [
      ...prev,
      { buildingId, layerId }, 
    ]);

    map.getLayer(`outline-${layerId}`) && map.removeLayer(`outline-${layerId}`);
    map.getSource(`outline-${layerId}`) &&
      map.removeSource(`outline-${layerId}`);
  };

  const saveBuildingToDatabase = async (
    coordinates: [number, number][],
    buildingId: string
  ) => {
    const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
    const response = await fetch(
      `${API_BASE_URL}/api/createBuilding`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          buildingId,
          coordinates,
          projectId,
          userId: user?.uid,
        }),
      }
    );

    if (response.ok) {
      console.log("Building saved successfully!");
    } else {
      console.error("Failed to save building");
    }
  };

  const updateBuildings = async (
    dataBuildings: Building[],
    buildingData: Record<string, BuildingAnswer[]>,
    layers: Layer[]
  ) => {
    if (!map) return;
    createdBuildings.forEach(({ layerId }) => {
      if (map.getLayer(layerId)) map.removeLayer(layerId);
      if (map.getSource(layerId)) map.removeSource(layerId);
    });
    setCreatedBuildings([]);
    dataBuildings.forEach((building) => {
      const { buildingId, coordinates } = building;

      if (!Array.isArray(coordinates) || coordinates.length < 3) {
        console.error(`Invalid coordinates for building ${buildingId}`);
        return;
      }

      console.log("coordinates");
      console.log(coordinates);
      // const polygonCoords = coordinates as number[][][];
      // const formattedCoordinates = [
      //   polygonCoords[0].map((coord) => [coord[0], coord[1]]),
      // ];
      const formattedCoordinates: number[][] = coordinates
        .map((coord) => {
          // ตรวจสอบว่า coord เป็น number[] และเป็นคู่ค่า
          if (
            Array.isArray(coord) &&
            coord.length === 2 &&
            coord.every((val) => typeof val === "number")
          ) {
            return [coord[0], coord[1]]; 
          }
          return []; 
        })
        .filter((coord) => coord.length === 2);

      const buildingGeoJSON: GeoJSON.FeatureCollection = {
        type: "FeatureCollection",
        features: [
          {
            type: "Feature",
            geometry: {
              type: "Polygon",
              coordinates: [formattedCoordinates],
            },
            properties: {
              buildingId,
            },
          },
        ],
      };

      const layerId = `building-layer-${buildingId}`;

      if (!map.getSource(layerId)) {
        map.addSource(layerId, {
          type: "geojson",
          data: buildingGeoJSON,
        });
      }

      if (!map.getLayer(layerId)) {
        map.addLayer({
          id: layerId,
          type: "fill",
          source: layerId,
          paint: {
            "fill-color": "#D9D3C9", 
            // "fill-opacity": 0.5,
          },
        });
      }

      setCreatedBuildings((prev) => [...prev, { buildingId, layerId }]);
    });

    layers.forEach((layer) => {
      if (!layer.visible) return;

      const buildingsInLayer = buildingData[layer.id] || [];

      buildingsInLayer.forEach((building) => {
        const { buildingId, color } = building;
        const layerId = `building-layer-${buildingId}`;

        if (map.getLayer(layerId)) {
          map.setPaintProperty(layerId, "fill-color", color || "#D9D3C9");
        }
      });
    });
  };

  // const [buildingsFetched, setBuildingsFetched] = useState(false);
  const buildingsFetched = false;

  useEffect(() => {
    const fetchAndUpdateBuildings = async () => {
      try {
        if (buildingsFetched) return;
        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL

        const response = await fetch(
         `${API_BASE_URL}/api/getBuildings/${projectId}?userId=${user?.uid}`
        );
        const data = await response.json();

        if (data.message === "Buildings retrieved successfully") {
          console.log("Buildings:", data.buildings);

          updateBuildings(data.buildings, buildingData, layers);

          // setBuildingsFetched(true);
        } else {
          console.error("Error fetching buildings:", data.message);
        }
      } catch (error) {
        console.error("Error:", error);
      }
    };

    if (projectId && user?.uid) {
      fetchAndUpdateBuildings();
    }
  }, [projectId, user?.uid, map, buildingsFetched, layers]);

  const [dataBuildings, setDataBuildings] = useState<Building[]>([]);

  const fetchBuildings = async () => {
    try {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      const response = await fetch(
      `${API_BASE_URL}/api/getBuildings/${projectId}?userId=${user?.uid}`
      );
      const data = await response.json();

      if (data.message === "Buildings retrieved successfully") {
        console.log("Buildings:", data.buildings);

        setDataBuildings(data.buildings);
      } else {
        console.error("Error fetching buildings:", data.message);
      }
    } catch (error) {
      console.error("Error:", error);
    }
  };

  useEffect(() => {
    if (projectId && user?.uid) {
      fetchBuildings();
    }
  }, [projectId, user?.uid]);

  useEffect(() => {
    if (map && dataBuildings.length > 0) {
      updateBuildings(dataBuildings, buildingData, layers);
    }
  }, [buildingData, layers, map, dataBuildings]);

  const [showPopup, setShowPopup] = useState(false);

  const closePopup = () => {
    setShowPopup(false);
  };

  return (
    <>
      <div ref={mapContainerRef} className="w-full h-full" />
      {showPopup && (
        <TextPopup
          key="popup"
          coordinates={tempInfo.coordinates}
          description={tempInfo.description || "Default text"} 
          handleSave={(newDescription) => handlesavetext(newDescription)} 
          closePopup={closePopup}
        />
      )}

      {popupInfo && (
        <PopupComponent
          title={popupInfo.title}
          description={popupInfo.description}
          lng={popupInfo.lng}
          lat={popupInfo.lat}
          onClose={handleClosePopup}
          onSave={handleSave}
          onDelete={handleDeleteMarker}
          color={popupInfo.color}
          iconName={popupInfo.iconName}
        />
      )}
      {popupPathInfo && (
        <PathPopup
          id={popupPathInfo.id}
          name={popupPathInfo.name}
          description={popupPathInfo.description}
          thickness={popupPathInfo.thickness}
          color={popupPathInfo.color}
          onSave={handleSavePath}
          onDelete={() => handleDeletePath(popupPathInfo.id)}
          onClose={() => setPopupPathInfo(null)}
        />
      )}
      {selectedButton === "path" &&
        selectedLayer?.id.startsWith("layer-symbol-") && (
          <button
            onClick={handlePathButtonClick}
            disabled={isDrawingPath && tempPoints.length < 2}
            className="fixed top-4 right-4 px-4 py-2 bg-blue-500 text-white rounded-lg "
          >
            {isDrawingPath ? "บันทึก" : "เพิ่มเส้นทาง"}
          </button>
        )}
      {buildingInfo && (
        <BuildingPopup
          buildingName={buildingInfo.name}
          id={buildingInfo.id}
          questions={buildingInfo.questions}
          coordinates={buildingInfo.coordinates}
          onClose={() => setBuildingInfo(null)}
          onSaveAnswers={handleSaveAnswers}
          existingAnswers={answers[buildingInfo.id] || {}}
        />
      )}
      {selectedRelationship && (
        <EditPopup
          relationshipId={selectedRelationship.id}
          initialDescription={selectedRelationship.description}
          initialType={selectedRelationship.type}
          onSave={handleSavePopup}
          onCancel={handleCancelPopup}
          onDelete={handleDeleteRelationship}
        />
      )}

      {selectedLayer?.id.startsWith("layer-relationship-") && (
        <>
          <div className="absolute fixed rounded top-1 right-1 m-4 w-72 h-auto bg-white flex flex-col p-4 shadow-lg text-sm">
            <span className="font-semibold mb-4">คำอธิบาย</span>

            {/* เส้นตรง */}
            <div className="flex content-center items-center mb-2">
              <div className="w-6 h-1 border-b-2 border-black mr-2"></div>
              <input
                type="text"
                placeholder="เส้นตรง"
                value={solidLine}
                onChange={(e) => setSolidLine(e.target.value)}
                className="border border-gray-300 rounded px-2 py-1 flex-1"
              />
            </div>

            <div className="flex items-center mb-2 gap-2">
              {/* เส้นขนาน */}
              <div className="grid grid-rows items-center ">
                <div className="w-6 h-1 border-b-2 border-black"></div>
                <div className="w-6 h-1 border-b-2 border-black"></div>
              </div>
              <input
                type="text"
                placeholder="เส้นขนาน"
                value={parallelLine}
                onChange={(e) => setParallelLine(e.target.value)}
                className="border border-gray-300 rounded px-2 py-1 flex-1"
              />
            </div>

            {/* เส้นซิกแซก */}
            <div className="flex items-center mb-2">
              <div className="w-6 h-6 flex items-center justify-center mr-2">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  className="stroke-black"
                >
                  <path d="M2 20L8 4L16 20L22 4" fill="none" strokeWidth="2" />
                </svg>
              </div>
              <input
                type="text"
                placeholder="ซิกแซก"
                value={zigzagLine}
                onChange={(e) => setZigzagLine(e.target.value)}
                className="border border-gray-300 rounded px-2 py-1 flex-1"
              />
            </div>

            {/* เส้นประ */}
            <div className="flex items-center mb-2">
              <div className="w-6 h-1 border-b-2 border-dashed border-black mr-2"></div>
              <input
                type="text"
                placeholder="เส้นประ"
                value={dashedLine}
                onChange={(e) => setDashedLine(e.target.value)}
                className="border border-gray-300 rounded px-2 py-1 flex-1"
              />
            </div>
          </div>
        </>
      )}
    </>
  );
};

export default ProjectMap;
