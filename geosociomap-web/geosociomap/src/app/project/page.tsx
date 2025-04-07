"use client";

// import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import ProjectSidebar from "../component/ProjectSidebar";
// import { useSearchParams } from "next/navigation";
import { Project } from "../types";
import ProjectMap from "../component/ProjectMap";
import { Sarabun } from "next/font/google";
import Card from "../component/Card";
// import { StaticImageData } from "next/image";
// import { SvgIconProps } from "@mui/material/SvgIcon";
import CustomDropdown from "../component/CustomDropdown";
// type IconComponent = React.ComponentType<SvgIconProps>;
import AddIcon from "@mui/icons-material/Add";
// import { SketchPicker } from "react-color";
import ColorPicker from "../component/ColorPicker";
import ArrowDropUpIcon from "@mui/icons-material/ArrowDropUp";
import ArrowDropDownIcon from "@mui/icons-material/ArrowDropDown";
import axios from "axios";
import { Layer } from "../types/layer";
import { v4 as uuidv4 } from "uuid";
import {
  // NoteItem,
  // MainNote,
  // PositionNote,
  // SubNote,
  NoteSequence,
} from "../types/note";
import { FormType, LayerData, Question, QuestionType } from "../types/form";
import { useAuth } from "../hooks/useAuth";

// interface ProjectContextType {
//   project: Project | null;
//   setProject: (project: Project) => void;
// }

interface SelectedLayerData {
  data: LayerData[]; 
  layerId: string;
}

const sarabun = Sarabun({
  weight: ["400", "500", "600", "700"],
  subsets: ["thai", "latin"],
  display: "swap",
});

// const ProjectContext = createContext<ProjectContextType | undefined>(undefined);

const ProjectDetailPage: React.FC = () => {
  // const router = useRouter();
  const { user } = useAuth();
  // const searchParams = useSearchParams();
  // const id = searchParams.get("id");
  const [projectId, setProjectId] = useState<string | null>(null);
  const [project, setProject] = useState<Project | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedCard, setSelectedCard] = useState<number | null>(0);
  const [layers, setLayers] = useState<Layer[]>([]);
  const [selectedButton, setSelectedButton] = useState<string>("symbol");
  const [selectedLayer, setSelectedLayer] = useState<
    Layer | NoteSequence | null
  >(null);
  const [Layertype, setLayertype] = useState<string | null>(null);
  const [isFetching, setIsFetching] = useState(false);

  const [selectedForm, setSelectedForm] = useState<FormType>("personal_info");
  const [selectedOptions, setSelectedOptions] = useState<{
    [key: string]: string[];
  }>({});

  const [optionColors, setOptionColors] = useState<{ [key: string]: string }>(
    {}
  ); 
  const [showAddQuestionMenu, setShowAddQuestionMenu] = useState(false); 

  // const [selectedColor, setSelectedColor] = useState<string | null>(
  //   "transparent"
  // ); 
  const [showColorPicker, setShowColorPicker] = useState(false);
  const [activeColorOption, setActiveColorOption] = useState<{
    questionId: string;
    index: number;
  } | null>(null);

  // const [selectedQuestionId, setSelectedQuestionId] = useState<string | null>(
  //   null
  // );

  const [isCreatingBuilding, setIsCreatingBuilding] = useState(false);

  // const [activeColorPicker, setActiveColorPicker] = useState<{
  //   questionId: string;
  //   optionIndex: number;
  // } | null>(null); 
  const [selectedMode, setSelectedMode] = useState<"Add" | "Delete" | "Text" | "DeleteText" | null>(
    null
  );

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

  const formQuestions: Record<FormType, Question[]> = {
    personal_info: [
      { id: "1", label: "ผู้ให้ข้อมูล", type: "text" },
      { id: "2", label: "วัน/เดือน/ปีเกิด", type: "text" },
      { id: "3", label: "อายุ", type: "number" },
      {
        id: "4",
        label: "ศาสนา",
        type: "multiple_choice",
        options: [
          { label: "พุทธ", value: "buddhism" },
          { label: "คริสต์", value: "christian" },
          { label: "อิสลาม", value: "islam" },
        ],
        showMapToggle: true,
      },
      {
        id: "5",
        label: "สถานภาพ",
        type: "multiple_choice",
        options: [
          { label: "โสด", value: "single" },
          { label: "สมรส", value: "married" },
          { label: "หย่าร้าง", value: "divorced" },
          { label: "หม้าย", value: "widowed" },
        ],
        showMapToggle: true,
      },
      { id: "6", label: "โรคประจำตัว", type: "text" },
      {
        id: "7",
        label: "การเลือกรับบริการรักษาพยาบาล",
        type: "multiple_choice",
        options: [
          {
            label: "โรงพยาบาลส่งเสริมสุขภาพตำบล/อนามัย",
            value: "health_promotion_hospital",
          },
          {
            label: "โรงพยาบาลประจำอำเภอ/จังหวัด",
            value: "district_provincial_hospital",
          },
          { label: "ซื้อยากินเอง", value: "self_medication" },
          { label: "คลินิกเอกชน", value: "private_clinic" },
          { label: "โรงพยาบาลเอกชน", value: "private_hospital" },
          { label: "สถานพยาบาลอื่น ๆ", value: "other_healthcare" },
        ],
        showMapToggle: true,
      },
      {
        id: "8",
        label: "สิทธิด้านการรักษาพยาบาล",
        type: "multiple_choice",
        options: [
          {
            label: "สิทธิหลักประกันสุขภาพ/สิทธิ 30 บาท/สิทธิบัตรทอง",
            value: "universal_healthcare",
          },
          { label: "สิทธิประกันสังคม", value: "social_security" },
          {
            label: "สิทธิเบิกจ่ายตรงข้าราชการ",
            value: "government_reimbursement",
          },
        ],
        showMapToggle: true,
      },
      {
        id: "9",
        label: "ระดับการศึกษา",
        type: "multiple_choice",
        options: [
          { label: "ต่ำกว่าประถมศึกษา", value: "below_primary" },
          { label: "ประถมศึกษา", value: "primary" },
          { label: "มัธยมศึกษาตอนต้น", value: "lower_secondary" },
          {
            label: "มัธยมศึกษาตอนปลาย/ปวช.",
            value: "upper_secondary_or_vocational",
          },
          { label: "ปวส.หรือเทียบเท่า", value: "vocational_certificate" },
          { label: "ปริญญาตรี", value: "bachelors" },
          { label: "สูงกว่าปริญญาตรี", value: "postgraduate" },
        ],
        showMapToggle: true,
      },
      {
        id: "10",
        label: "อาชีพ",
        type: "multiple_choice",
        options: [
          { label: "ทำไร่/ทำนา/ทำสวน", value: "farmer" },
          { label: "รับราชการ", value: "government_employee" },
          { label: "เจ้าหน้าที่ของรัฐ", value: "state_officer" },
          { label: "พนักงานบริษัท/ลูกจ้างเอกชน", value: "private_employee" },
          { label: "รับจ้างทั่วไป", value: "freelancer" },
          { label: "ค้าขาย", value: "merchant" },
          { label: "กำลังศึกษา", value: "student" },
          { label: "เด็กอยู่ในความปกครอง", value: "under_guardianship" },
          { label: "อื่น ๆ ระบุ", value: "other" },
        ],
        showMapToggle: true,
      },
      {
        id: "11",
        label: "รายได้ครัวเรือนต่อปี",
        type: "multiple_choice",
        options: [
          { label: "พอใช้จ่ายในครัวเรือน", value: "sufficient" },
          { label: "เหลือเก็บ", value: "surplus" },
          { label: "เป็นหนี้", value: "debt" },
        ],
        showMapToggle: true,
      },
    ],
    community_issues: [
      {
        id: "1",
        label: "ปัญหาของชุมชน ทั้งปัจจุบันและคาดการณ์อนาคต",
        type: "checkbox",
        options: [
          { label: "โครงสร้างพื้นฐานสาธารณูปโภค", value: "infrastructure" },
          { label: "อาชีพ รายได้", value: "income_jobs" },
          { label: "ทรัพยากรธรรมชาติ ดิน นา ป่า", value: "natural_resources" },
          { label: "สิ่งแวดล้อม มลพิษ", value: "environment_pollution" },
          { label: "ยาเสพติด", value: "drugs" },
          { label: "ภัยพิบัติ", value: "disasters" },
          { label: "ศิลปะ วัฒนธรรม ประเพณี", value: "culture_traditions" },
        ],
        showMapToggle: true,
      },
      {
        id: "2",
        label:
          "ความต้องการต่อชุมชนในอนาคต ครอบครัวของท่านอยากให้ชุมชน/หมู่บ้านที่อาศัยอยู่เป็นอย่างไรในอนาคต",
        type: "text",
      },
    ],
    utilities_info: [
      {
        id: "1",
        label: "ไฟฟ้า",
        type: "multiple_choice",
        options: [
          { label: "มี", value: "has_electricity" },
          { label: "ไม่มี", value: "no_electricity" },
        ],
        showMapToggle: true,
      },
      {
        id: "2",
        label: "น้ำสะอาดดื่มทั้งปี",
        type: "multiple_choice",
        options: [
          { label: "มี", value: "has_clean_drinking_water" },
          { label: "ไม่มี", value: "no_clean_drinking_water" },
        ],
        showMapToggle: true,
      },
      {
        id: "3",
        label: "ครัวเรือนน้ำใช้พอเพียงทั้งปี",
        type: "multiple_choice",
        options: [
          { label: "มี", value: "has_sufficient_water" },
          { label: "ไม่มี", value: "no_sufficient_water" },
        ],
        showMapToggle: true,
      },
      {
        id: "4",
        label: "แหล่งน้ำดื่มในครัวเรือน",
        type: "multiple_choice",
        options: [
          { label: "น้ำประปาหมู่บ้าน", value: "village_water_supply" },
          { label: "น้ำฝน", value: "rain_water" },
          { label: "น้ำบ่อตื้น", value: "shallow_well" },
          { label: "น้ำบาดาล", value: "groundwater" },
        ],
        showMapToggle: true,
      },
      {
        id: "5",
        label: "น้ำที่เอามาดื่มผ่านการทำความสะอาดหรือไม่",
        type: "multiple_choice",
        options: [
          { label: "ผ่านการทำความสะอาด", value: "cleaned" },
          { label: "ไม่ผ่านการทำความสะอาด", value: "not_cleaned" },
        ],
        showMapToggle: true,
      },
      {
        id: "6",
        label: "วิธีการทำความสะอาดน้ำดื่ม",
        type: "multiple_choice",
        options: [
          { label: "ต้ม", value: "boil" },
          { label: "กรอง", value: "filter" },
        ],
        showMapToggle: true,
      }, // This question only appears if "ผ่านการทำความสะอาด" is selected
      {
        id: "7",
        label: "แหล่งน้ำใช้ในครัวเรือน",
        type: "multiple_choice",
        options: [
          { label: "น้ำประปาหมู่บ้าน", value: "village_water_supply" },
          { label: "น้ำฝน", value: "rain_water" },
          { label: "น้ำบ่อตื้น", value: "shallow_well" },
          { label: "น้ำบาดาล", value: "groundwater" },
          { label: "น้ำสระ บึง หนอง", value: "lake_pond" },
        ],
        showMapToggle: true,
      },
      {
        id: "8",
        label: "น้ำที่เอามาใช้ผ่านการทำความสะอาดหรือไม่",
        type: "multiple_choice",
        options: [
          { label: "ผ่านการทำความสะอาด", value: "cleaned" },
          { label: "ไม่ผ่านการทำความสะอาด", value: "not_cleaned" },
        ],
        showMapToggle: true,
      },
      {
        id: "9",
        label: "วิธีการทำความสะอาดน้ำใช้",
        type: "multiple_choice",
        options: [
          { label: "เติมคลอรีน", value: "chlorine" },
          { label: "แกว่งสารส้ม", value: "alum" },
          { label: "กรอง", value: "filter" },
        ],
        showMapToggle: true,
      }, 
      {
        id: "10",
        label: "โทรศัพท์บ้าน/โทรศัพท์เคลื่อนที่",
        type: "multiple_choice",
        options: [
          { label: "มี", value: "has_phone" }, 
          { label: "ไม่มี", value: "no_phone" },
        ],
        showMapToggle: true,
      },
      {
        id: "11",
        label: "ในครัวเรือนมียานพาหนะที่ใช้ในการเดินทางหรือไม่",
        type: "multiple_choice",
        options: [
          { label: "มี", value: "has_vehicle" },
          { label: "ไม่มี", value: "no_vehicle" },
        ],
        showMapToggle: true,
      },
      {
        id: "12",
        label: "ประเภทยานพาหนะ",
        type: "checkbox",
        options: [
          { label: "รถยนต์(กระบะ/เก๋ง)", value: "car" },
          { label: "รถทางการเกษตร เช่น รถไถ", value: "agricultural_vehicle" },
          { label: "รถจักรยานยนต์", value: "motorcycle" },
          { label: "รถจักรยาน", value: "bicycle" },
          { label: "อื่น ๆ", value: "other_vehicle" }, 
        ],
      }, 
      {
        id: "13",
        label: "การสวมหมวกกันน็อก/รัดเข็มขัดนิรภัย",
        type: "multiple_choice",
        options: [
          { label: "ไม่เคยใช้เลย", value: "never" },
          { label: "ใช้บางครั้ง", value: "sometimes" },
          { label: "ใช้ทุกครั้ง", value: "always" },
        ],
        showMapToggle: true,
      },
    ],
    financial_info: [
      {
        id: "1",
        label: "ความสามารถในการออมทรัพย์ของครัวเรือน",
        type: "number",
      },

      {
        id: "2",
        label: "จำนวนหนี้สินนอกระบบ (ที่อยู่อาศัย)",
        type: "number",
      },
      {
        id: "3",
        label: "จำนวนหนี้สินนอกระบบ (อาชีพ)",
        type: "number",
      },
      {
        id: "4",
        label: "จำนวนหนี้สินนอกระบบ (อื่น ๆ)",
        type: "number",
      },

      {
        id: "5",
        label: "จำนวนหนี้สินในระบบ (ที่อยู่อาศัย)",
        type: "number",
      },
      {
        id: "6",
        label: "จำนวนหนี้สินในระบบ (อาชีพ)",
        type: "number",
      },
      {
        id: "7",
        label: "จำนวนหนี้สินในระบบ (อื่น ๆ)",
        type: "number",
      },
    ], 

    tourism: [
      { id: "1", label: "ชื่อแหล่งท่องเที่ยว", type: "text" },
      { id: "2", label: "ที่ตั้ง", type: "text" },
      { id: "3", label: "พิกัด GPS", type: "text" },
      { id: "4", label: "ความเป็นมาของแหล่งท่องเที่ยว", type: "text" },
      { id: "5", label: "จุดเด่นของแหล่งท่องเที่ยว", type: "text" },
      {
        id: "6",
        label: "รูปแบบและการท่องเที่ยว",
        type: "multiple_choice",
        options: [
          {
            label: "รูปแบบการท่องเที่ยวในแหล่งธรรมชาติ",
            value: "nature_tourism",
          },
          {
            label: "รูปแบบการท่องเที่ยวในแหล่งวัฒนธรรม",
            value: "cultural_tourism",
          },
          {
            label: "รูปแบบการท่องเที่ยวเชิงสิ่งก่อสร้าง",
            value: "construction_tourism",
          },
          { label: "รูปแบบการท่องเที่ยวอื่น ๆ", value: "other_tourism" },
        ],
        showMapToggle: true,
      },
      {
        id: "7",
        label: "ความพร้อมในการให้บริการ",
        type: "multiple_choice",
        options: [
          {
            label: "ระดับ 3 มีความพร้อมด้านสาธารณูปโภคครบถ้วน",
            value: "level_3",
          },
          {
            label: "ระดับ 2 มีความพร้อมด้านสาธารณูปโภคปานกลาง",
            value: "level_2",
          },
          { label: "ระดับ 1 มีความพร้อมด้านสาธารณูปโภคน้อย", value: "level_1" },
        ],
        showMapToggle: true,
      },
      {
        id: "8",
        label: "สิ่งอำนวยความสะดวก",
        type: "checkbox",
        options: [
          { label: "ห้องน้ำ", value: "restroom" },
          { label: "ไฟส่องสว่าง", value: "lighting" },
          { label: "สัญญาณอินเตอร์เน็ต", value: "internet_signal" },
          { label: "ถนน", value: "road" },
          { label: "ป้ายบอกทาง", value: "direction_sign" },
          { label: "มัคคุเทศก์", value: "guide" },
          { label: "ที่พัก", value: "accommodation" },
          { label: "ร้านอาหาร", value: "restaurant" },
          { label: "ของที่ระลึก", value: "souvenirs" },
          { label: "กฎระเบียบ", value: "regulations" },
        ],
        showMapToggle: true,
      },
      { id: "9", label: "ต้องการเพิ่มเติม (ระบุ)", type: "text" },
    ], 
    health: [
      {
        id: "1",
        label: "โรคประจำตัว",
        type: "multiple_choice",
        options: [
          { label: "เบาหวาน", value: "diabetes" },
          { label: "ความดันโลหิตสูง", value: "hypertension" },
          { label: "โรคหัวใจ", value: "heart_disease" },
          { label: "โรคปอด", value: "lung_disease" },
        ],
        showMapToggle: true,
      },
      {
        id: "2",
        label: "ในครัวเรือนมีการรับประทานอาหารแบบสุก ๆ ดิบ ๆ หรือไม่",
        type: "multiple_choice",
        options: [
          { label: "รับประทาน", value: "eat_raw_cooked" },
          { label: "ไม่รับประทาน", value: "no_raw_cooked" },
        ],
        showMapToggle: true,
      },
      {
        id: "3",
        label: "ในครัวเรือนมีการบริโภคผงชูรส",
        type: "multiple_choice",
        options: [
          { label: "รับประทาน", value: "eat_msg" },
          { label: "ไม่รับประทาน", value: "no_msg" },
        ],
        showMapToggle: true,
      },
      {
        id: "4",
        label: "สมาชิกในครัวเรือนมีคนดื่มสุรา/เบียร์",
        type: "multiple_choice",
        options: [
          { label: "ดื่ม", value: "drinks_alcohol" }, 
          { label: "ไม่ดื่ม", value: "no_alcohol" },
        ],
        showMapToggle: true,
      },
      {
        id: "5",
        label: "สมาชิกในครัวเรือนมีคนสูบบุหรี่/ยาเส้น",
        type: "multiple_choice",
        options: [
          { label: "สูบ", value: "smokes_tobacco" }, 
          { label: "ไม่สูบ", value: "no_tobacco" },
        ],
        showMapToggle: true,
      },
      {
        id: "6",
        label: "สมาชิกในครัวเรือนมีการใช้ยาเสพติดหรือไม่",
        type: "multiple_choice",
        options: [
          { label: "มี", value: "uses_drugs" },
          { label: "ไม่มี", value: "no_drugs" },
        ],
        showMapToggle: true,
      },
      {
        id: "7",
        label: "สมาชิกในครัวเรือนมีการตรวจสุขภาพประจำปีหรือไม่",
        type: "multiple_choice",
        options: [
          { label: "มี", value: "annual_health_check" },
          { label: "ไม่มี", value: "no_health_check" },
        ],
        showMapToggle: true,
      },
      {
        id: "8",
        label: "สมาชิกในครัวเรือนมีการออกกำลังกายเป็นประจำหรือไม่",
        type: "multiple_choice",
        options: [
          { label: "ออกเป็นประจำ", value: "exercises_regularly" },
          { label: "ไม่ออกเป็นประจำ", value: "no_regular_exercise" },
        ],
        showMapToggle: true,
      },
    ],
    custom: [],
  };

  const [questions, setQuestions] = useState<Question[]>(
    formQuestions[selectedForm]
  );

  useEffect(() => {
    setQuestions(formQuestions[selectedForm]);
  }, [selectedForm]); 

  // const [layerMarkers, setLayerMarkers] = useState<{
  //   [key: string]: mapboxgl.Marker[];
  // }>({});
  //   const [selectedCard, setSelectedCard] = useState(null);
  const [currentStep, setCurrentStep] = useState(0);

  const cards = [
    {
      id: "layer-symbol",
      title: "เลเยอร์สัญลักษณ์",
      description: "เพิ่มสัญลักษณ์ที่ต้องการบนแผนที่",
      imageUrl:
        "https://drive.google.com/uc?export=view&id=1ZsTT7A-Rf7bxFxV_q1kIBPVpwmZUeIBk",
      visible: true,
    },
    {
      id: "layer-relationship", 
      title: "เลเยอร์ความสัมพันธ์",
      description: "",
      imageUrl:
        "https://drive.google.com/uc?export=view&id=1ZsTT7A-Rf7bxFxV_q1kIBPVpwmZUeIBk",
      visible: true,
    },
    {
      id: "layer-form", 
      title: "เลเยอร์แบบฟอร์ม",
      description: "เลือกหรือสร้างแบบฟอร์มสำหรับกรอกข้อมูล",
      imageUrl:
        "https://drive.google.com/uc?export=view&id=1ZsTT7A-Rf7bxFxV_q1kIBPVpwmZUeIBk",
      visible: true,
    },
  ];

  const dropdownOptions = [
    { value: "personal_info", label: "ข้อมูลส่วนบุคคลทั่วไป" },
    {
      value: "utilities_info",
      label: "ข้อมูลสาธารณูปโภคและสิ่งอำนวยความสะดวก",
    },
    { value: "community_issues", label: "ปัญหาของชุมชน" },
    { value: "financial_info", label: "ความสามารถในการออมทรัพย์ของครัวเรือน" },
    { value: "tourism", label: "ด้านการท่องเที่ยวของชุมชน" },
    { value: "health", label: "ด้านสุขภาพ" },
    { value: "custom", label: "กำหนดเอง" },
  ];

  // const [loading, setLoading] = useState(true);
  // const [error, setError] = useState<string | null>(null);
  // const [layerStats, setLayerStats] = useState<any[]>([]); 
  const [selectedFormLayer, setSelectedFormLayer] = useState<string>(""); 
  const [selectedLayerData, setSelectedLayerData] =
    useState<SelectedLayerData | null>(null);
  const [isDeletingBuilding, setIsDeletingBuilding] = useState(false); 

  // useEffect(() => {
  //   const layer = layerStats.find(
  //     (layer) => layer.layerId === selectedFormLayer
  //   );
  //   if (layer) {
  //     setSelectedLayerData(layer); 
  //   }
  // }, [selectedFormLayer, layerStats]);

  useEffect(() => {
    if (projectId && user?.uid) {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      fetch(`${API_BASE_URL}/layers/${projectId}?userId=${user?.uid}`)
        .then((response) => response.json())
        .then((data) => {
          console.log("Fetched layers (before filtering):", data);
          const filteredLayers = data.filter((layer:Layer) => layer.isDeleted === false);
  
          console.log("Filtered layers:", filteredLayers);
          setLayers(filteredLayers);
        })
        .catch((error) => {
          console.error("Error fetching layers:", error);
        });
    }
  }, [projectId, user?.uid]);
  
  useEffect(() => {
    const fetchLayerStats = async () => {
      if (!layers || layers.length === 0) {
        console.log("No layers found. Skipping fetch.");
        return;
      }

      try {
       
        const layersToFetch = layers.filter((layer) =>
          layer.id.startsWith("layer-form-")
        );

      
        for (const layer of layersToFetch) {
         
          if (selectedFormLayer=='') continue;
          const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
          const response = await fetch(
            `${API_BASE_URL}/layers/${selectedFormLayer}/buildings?userId=${user?.uid}` 
          );

          if (response.ok) {
            const data = await response.json();
            console.log(`Data for layer ${layer.id}:`, data);

            setSelectedLayerData({ layerId: layer.id, data: data });

            // setLayerStats((prevStats) => [
            //   ...prevStats,
            //   { layerId: layer.id, data },
            // ]);
          }
        }
      } catch (err) {
        console.error("Error fetching layer stats:", err);
      }
    };

    fetchLayerStats();
  }, [layers, selectedFormLayer]);

  // useEffect(() => {
  //   console.log("layerStats");
  //   console.log(layerStats);
  // }, [layerStats]);

  const toggleModal = () => {
    setIsModalOpen(!isModalOpen);
  };

  const handleConfirm = () => {
    if (selectedCard === 0) {
      addLayer("layer-symbol");
      setLayertype("symbol");
      toggleModal();
    } else if (selectedCard === 1) {
      addLayer("layer-relationship");
      setLayertype("relationship");
      toggleModal();
    } else if (selectedCard === 2) {
      setCurrentStep(1); 
    }
  };

  const handleFormConfirm = () => {
    console.log(questions);
    addLayerForm();
    setLayertype("form");
    toggleModal();
  };


  const addLayerForm = async () => {
    const existingLayer = cards.find((card) => card.id === "layer-form");
    console.log("existingLayer", existingLayer);

    if (existingLayer) {
      try {
        const newOrder = layers.length > 0 ? layers.length + 1 : 1;

        const newLayer = {
          ...existingLayer,
          id: `layer-form-${uuidv4()}`, 
          order: newOrder,
          paths: [], 
          markers: [],
          questions: questions, 
          userId: user?.uid,
          sharedWith: [],
          isDeleted: false,
          lastUpdate: new Date().toISOString(),
        };

        setLayers((prevLayers) => {
          if (Array.isArray(prevLayers)) {
            return [...prevLayers, newLayer]; 
          }
          return [newLayer]; 
        });

    
        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
        const layerResponse = await axios.post(
         `${API_BASE_URL}/add-layer`,
          {
            projectId: projectId,
            layer: newLayer,
          }
        );

        console.log("Layer-form added successfully:", layerResponse.data);
      } catch (error) {
        console.error("Failed to add layer-form:", error);
      }
    }
  };

 
  const addLayer = async (layerId: string) => {
    const existingLayer = cards.find((card) => card.id === layerId);

    if (existingLayer) {
      try {
        const newOrder = layers.length > 0 ? layers.length + 1 : 1;

        const newLayer = {
          ...existingLayer,
          id: `${layerId}-${uuidv4()}`, 
          order: newOrder,
          paths: [], 
          markers: [],
          questions: [],
          userId: user?.uid, 
          sharedWith: [],
          isDeleted: false,
          lastUpdate: new Date().toISOString(),
        };

        setLayers((prevLayers) => {
          if (Array.isArray(prevLayers)) {
            return [...prevLayers, newLayer]; 
          }
          return [newLayer];
        });

        const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
        const layerResponse = await axios.post(
         `${API_BASE_URL}/add-layer`,
          {
            projectId: projectId,
            layer: newLayer,
          }
        );

        console.log("Layer added successfully:", layerResponse.data);
      } catch (error) {
        console.error("Failed to add layer:", error);
      }
    }
  };

  useEffect(() => {
    const searchParams = new URLSearchParams(window.location.search);
    const id = searchParams.get("id"); 
    if (id) {
      setProjectId(id);
    }
  }, []);

  useEffect(() => {
    if (projectId) {
      const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL
      fetch(`${API_BASE_URL}/project/${projectId}`)
        .then((response) => response.json())
        .then((data) => setProject(data));
    }
  }, [projectId]);

  const [noteData, setNoteData] = useState<NoteSequence | null>(null);
  // const [isNoteFetched, setIsNoteFetched] = useState(false); 

  useEffect(() => {
    const fetchNoteData = async () => {
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
          
        }

        const data = await response.json();
        console.log("Fetched note data:", data);
        setIsFetching(true);

        setNoteData(data);
      } catch (error) {
        console.error("Error fetching note data:", error);
      }
    };

    fetchNoteData();
  }, [projectId, user?.uid]);

  //   useEffect(() => {
  //     console.log("Layers updated: ", layers);
  //   }, [layers]);
  const handleBack = () => {
    setCurrentStep(0);
  };

  const handleOptionLabelChange = (
    questionId: string,
    index: number,
    newLabel: string
  ) => {
    setQuestions((prevQuestions) =>
      prevQuestions.map((q) =>
        q.id === questionId
          ? {
              ...q,
              options: q.options?.map((opt, i) =>
                i === index ? { ...opt, label: newLabel } : opt
              ),
            }
          : q
      )
    );
  };

  const handleAddOption = (questionId: string) => {
    setQuestions((prevQuestions) =>
      prevQuestions.map((q) =>
        q.id === questionId
          ? {
              ...q,
              options: [
                ...(q.options || []), 
                { value: `option-${(q.options?.length || 0) + 1}`, label: "" }, 
              ],
            }
          : q
      )
    );
  };

  const handleNumberChange = (questionId: string, value: string) => {
    setQuestions((prevQuestions) =>
      prevQuestions.map((q) =>
        q.id === questionId ? { ...q, answer: value } : q
      )
    );
  };

  const handleRemoveOption = (questionId: string, index: number) => {
    setQuestions((prevQuestions) =>
      prevQuestions.map((q) =>
        q.id === questionId
          ? {
              ...q,
              options: q.options?.filter((_, i) => i !== index) || [], 
            }
          : q
      )
    );
  };

  const handleShowOnMapToggle = (questionId: string) => {
    resetOptionColors();
    setQuestions((prevQuestions) =>
      prevQuestions.map(
        (q) =>
          q.id === questionId
            ? { ...q, showOnMap: true } 
            : { ...q, showOnMap: false } 
      )
    );
  };

 
  const resetOptionColors = () => {
    setOptionColors({}); 
    // setSelectedColor("transparent");
    setShowColorPicker(false); 
    setActiveColorOption(null);
  };

  
  const openColorPicker = (questionId: string, index: number) => {
    setActiveColorOption({ questionId, index });
    setShowColorPicker(true); 
  };

 
  const closeColorPicker = () => {
    setShowColorPicker(false);
  };


  const handleSelectColor = (color: string) => {
    if (activeColorOption) {
      setOptionColors((prev) => ({
        ...prev,
        [`${activeColorOption.questionId}-${activeColorOption.index}`]: color, 
      }));

      setQuestions((prevQuestions) => {
        const updatedQuestions = prevQuestions.map((question) => {
          if (question.id === activeColorOption.questionId) {
            
            const updatedOptions = question.options
              ? [...question.options] 
              : [];
         
            updatedOptions[activeColorOption.index] = {
              ...updatedOptions[activeColorOption.index],
              color: color, 
            };

            return { ...question, options: updatedOptions };
          }
          return question; 
        });

        return updatedQuestions; 
      });
    }

    // setSelectedColor(color);
    closeColorPicker();
  };

  const moveQuestionUp = (index: number) => {
    setQuestions((prevQuestions) => {
      if (index > 0) {
        const newQuestions = [...prevQuestions];
        const temp = newQuestions[index - 1];
        newQuestions[index - 1] = newQuestions[index];
        newQuestions[index] = temp;
        return newQuestions;
      }
      return prevQuestions;
    });
  };

  const moveQuestionDown = (index: number) => {
    setQuestions((prevQuestions) => {
      if (index < prevQuestions.length - 1) {
        const newQuestions = [...prevQuestions];
        const temp = newQuestions[index + 1];
        newQuestions[index + 1] = newQuestions[index];
        newQuestions[index] = temp;
        return newQuestions;
      }
      return prevQuestions; 
    });
  };

  const handleDeleteQuestion = (questionId: string) => {
    setQuestions((prevQuestions) =>
      prevQuestions.filter((q) => q.id !== questionId)
    );
  };

  const handleAddQuestion = (type: QuestionType) => {
    const newQuestion: Question = {
      id: Math.random().toString(),
      label: "คำถามใหม่", 
      type: type, 
      options:
        type === "multiple_choice" ? [{ label: "", value: "" }] : undefined, 
      showMapToggle: type === "multiple_choice" ? true : undefined, 
      showOnMap: false,
    };

    setQuestions((prevQuestions) => [...prevQuestions, newQuestion]); 
    setShowAddQuestionMenu(false);
  };

  const handleLabelChange = (questionId: string, newLabel: string) => {
    setQuestions((prevQuestions) =>
      prevQuestions.map((q) =>
        q.id === questionId ? { ...q, label: newLabel } : q
      )
    );
  };

  return (
    <div className={`flex w-full  bg-blue-100 ${sarabun.className}`}>
      {isModalOpen && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
          <div className="flex flex-col justify-center bg-white rounded-lg p-6 w-2/5 z-50">
            <h2 className="font-bold mb-4">เพิ่มเลเยอร์</h2>

       
            {currentStep === 0 && (
              <div className="grid grid-cols-3 gap-4">
                {cards.map((card, index) => (
                  <Card
                    key={index}
                    title={card.title}
                    description={card.description}
                    imageUrl={card.imageUrl}
                    isSelected={selectedCard === index}
                    onClick={() => setSelectedCard(index)}
                  />
                ))}
              </div>
            )}
            {currentStep === 1 && (
              <div className="flex w-full transition-transform transform translate-x-0">
                <div className="flex flex-col w-full gap-3 ">
                  <div className="w-full">
                    <CustomDropdown
                      options={dropdownOptions}
                      label="เลือกแบบฟอร์ม"
                      selectedValue={selectedForm}
                      onSelect={setSelectedForm}
                    />
                  </div>
                  <div className="bg-stone-100 flex flex-col w-full h-96 rounded p-4">
                    <div className="relative">
                      <div
                        onClick={() =>
                          setShowAddQuestionMenu(!showAddQuestionMenu)
                        }
                        className="flex justify-end text-sm text-blue-600 cursor-pointer"
                      >
                        เพิ่มคำถาม
                      </div>

                      {showAddQuestionMenu && (
                        <div className="absolute right-0 mt-2 bg-white border rounded p-2 shadow-lg z-10 text-sm">
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
                    </div>

                    <div className="flex justify-center text-stone-600  overflow-y-auto w-full h-80">
                      <div className="px-4 grid justify-center gap-2">
                        {questions.map((question, index) => (
                          <div
                            className="grid grid-cols gap-2"
                            key={question.id}
                          >
                            <div>
                              <div className="flex justify-between w-96 items-center">
                                <div className="flex w-full">
                                  <input
                                    className="w-full h-6 rounded text-sm px-2 bg-stone-100"
                                    placeholder="แก้ไขคำถามที่นี่"
                                    value={question.label} 
                                    onChange={(e) =>
                                      handleLabelChange(
                                        question.id,
                                        e.target.value
                                      )
                                    } 
                                  />
                                </div>

                                <div className="flex text-xs gap-2  items-center mt-2">
                              
                                  <button
                                    onClick={() => moveQuestionUp(index)}
                                    className={`text-blue-600 text-xs ${
                                      index === 0 &&
                                      "opacity-50 cursor-not-allowed"
                                    }`}
                                    disabled={index === 0} 
                                  >
                                    <ArrowDropUpIcon />
                                  </button>

                              
                                  <button
                                    onClick={() => moveQuestionDown(index)}
                                    className={`text-blue-600 text-xs ${
                                      index === questions.length - 1 &&
                                      "opacity-50 cursor-not-allowed"
                                    }`}
                                    disabled={index === questions.length - 1} 
                                  >
                                    <ArrowDropDownIcon />
                                  </button>

                                  <button
                                    onClick={() =>
                                      handleDeleteQuestion(question.id)
                                    }
                                    className="text-red-600 text-xs"
                                  >
                                    &#10005;
                                  </button>
                                </div>
                              </div>
                              {question.type === "text" && (
                                <div className="flex w-full">
                                  <input
                                    className="w-full h-10 rounded text-sm px-2"
                                    placeholder={question.label}
                                    type="text"
                                  />
                                </div>
                              )}
                              {question.type === "number" && (
                                <div className="flex w-full">
                                  <input
                                    type="number"
                                    step="0.01" 
                                    value={question.answer || ""} 
                                    onChange={(e) => {
                                      const value = e.target.value;
                                      if (/^\d*\.?\d*$/.test(value)) {
                                        handleNumberChange(question.id, value);
                                      }
                                    }}
                                    className="w-full h-10 rounded text-sm border bg-white p-1"
                                    placeholder={question.label} 
                                  />
                                </div>
                              )}

                              {question.type === "multiple_choice" && (
                                <div className="bg-white rounded p-4 text-sm w-96 gap-1 grid">
                                  {question.showMapToggle && (
                                    <div className="flex gap-2 p-1 content-center text-xs text-blue-500 justify-end items-center">
                                      <input
                                        type="radio"
                                        checked={question.showOnMap}
                                        onChange={() =>
                                          handleShowOnMapToggle(question.id)
                                        }
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
                                              activeColorOption.index ===
                                                index && (
                                                <ColorPicker
                                                  colors={colors.filter(
                                                    (color) =>
                                                      !Object.values(
                                                        optionColors
                                                      ).includes(color) 
                                                  )}
                                                  onSelectColor={
                                                    handleSelectColor
                                                  }
                                                  onClose={closeColorPicker}
                                                />
                                              )}

                                            <div
                                              onClick={() =>
                                                openColorPicker(
                                                  question.id,
                                                  index
                                                )
                                              } 
                                              style={{
                                                backgroundColor:
                                                  optionColors[
                                                    `${question.id}-${index}`
                                                  ] || "transparent",
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
                                      onClick={() =>
                                        handleAddOption(question.id)
                                      }
                                      className="text-blue-600 text-sm"
                                    >
                                      เพิ่มตัวเลือก
                                    </button>
                                  </div>
                                </div>
                              )}

                              {question.type === "checkbox" && (
                                <div className="bg-white rounded p-4 text-sm w-96 gap-1 grid">
                                  {question.showMapToggle && (
                                    <div className="flex gap-2 p-1 content-center text-xs text-blue-500 justify-end items-center">
                                      <input
                                        type="radio"
                                        checked={question.showOnMap}
                                        onChange={() =>
                                          handleShowOnMapToggle(question.id)
                                        }
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
                                              activeColorOption.index ===
                                                index && (
                                                <ColorPicker
                                                  colors={colors.filter(
                                                    (color) =>
                                                      !Object.values(
                                                        optionColors
                                                      ).includes(color) 
                                                  )}
                                                  onSelectColor={(
                                                    selectedColor
                                                  ) =>
                                                    handleSelectColor(
                                                      selectedColor
                                                    )
                                                  }
                                                  onClose={closeColorPicker}
                                                />
                                              )}

                                            
                                            <div
                                              onClick={() =>
                                                openColorPicker(
                                                  question.id,
                                                  index
                                                )
                                              }
                                              style={{
                                                backgroundColor:
                                                  optionColors[
                                                    `${question.id}-${index}`
                                                  ] || "transparent",
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
                                      onClick={() =>
                                        handleAddOption(question.id)
                                      }
                                      className="text-blue-600 text-sm"
                                    >
                                      เพิ่มตัวเลือก
                                    </button>
                                  </div>
                                </div>
                              )}
                        
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            <div className="flex justify-end gap-6 ">
              {currentStep === 1 ? (
                <button
                  className="mt-4 text-blue-500 font-bold rounded py-2"
                  onClick={handleBack} 
                >
                  ย้อนกลับ
                </button>
              ) : (
                <button
                  className="mt-4 text-blue-500 font-bold rounded py-2"
                  onClick={toggleModal}
                >
                  ยกเลิก
                </button>
              )}
              {selectedCard == 2 && currentStep == 0 && (
                <button
                  className="mt-4 bg-blue-500 hover:bg-blue-600 text-white w-24 rounded py-2 px-6 duration-300 ease-in-out transform"
                  onClick={handleConfirm}
                >
                  ต่อไป
                </button>
              )}
              {selectedCard != 2 && (
                <button
                  className="mt-4 bg-blue-500 hover:bg-blue-600 text-white w-24 rounded py-2 px-6 duration-300 ease-in-out transform"
                  onClick={handleConfirm}
                >
                  ยืนยัน
                </button>
              )}
              {currentStep == 1 && (
                <button
                  className="mt-4 bg-blue-500 hover:bg-blue-600 text-white w-24 rounded py-2 px-6 duration-300 ease-in-out transform"
                  onClick={handleFormConfirm}
                >
                  ยืนยัน
                </button>
              )}
            </div>
          </div>
        </div>
      )}
      <ProjectSidebar
        onAddClick={toggleModal}
        isModalOpen={isModalOpen}
        layers={layers}
        projectId={projectId}
        selectedButton={selectedButton}
        setSelectedButton={setSelectedButton}
        setLayers={setLayers}
        selectedLayer={selectedLayer}
        setSelectedLayer={setSelectedLayer}
        setLayertype={setLayertype}
        Layertype={Layertype}
        noteData={noteData}
        setNoteData={setNoteData}
        selectedOptions={selectedOptions}
        setSelectedOptions={setSelectedOptions}
        selectedLayerData={selectedLayerData}
        setIsFetching={setIsFetching}
        isFetching={isFetching}
        // layerStats={layerStats}
        // setLayerStats={setLayerStats}
        setSelectedFormLayer={setSelectedFormLayer}
        selectedFormLayer={selectedFormLayer}
        isCreatingBuilding={isCreatingBuilding}
        setIsCreatingBuilding={setIsCreatingBuilding}
        isDeletingBuilding={isDeletingBuilding}
        setIsDeletingBuilding={setIsDeletingBuilding}
        selectedMode={selectedMode}
        setSelectedMode={setSelectedMode}
      />
      <div className="w-full">
        <ProjectMap
          selectedPoints={project?.selectedPoints}
          selectedButton={selectedButton}
          layers={layers}
          setLayers={setLayers}
          selectedLayer={selectedLayer}
          setSelectedLayer={setSelectedLayer}
          noteData={noteData}
          setNoteData={setNoteData}
          selectedOptions={selectedOptions}
          selectedLayerData={selectedLayerData}
          isCreatingBuilding={isCreatingBuilding}
          projectId={projectId}
          isDeletingBuilding={isDeletingBuilding}
          selectedMode={selectedMode}
          setIsFetching={setIsFetching}
        />
      </div>

    </div>
  );
};

export default ProjectDetailPage;
