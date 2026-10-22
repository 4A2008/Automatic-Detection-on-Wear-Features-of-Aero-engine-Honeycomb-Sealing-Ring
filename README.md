# Automatic Detection on Wear Features of Aero-engine Honeycomb Sealing Ring

**Published by:** Elsevier  
**Published Date:** 2025-02-28  
**URL:** https://www.sciencedirect.com/science/article/abs/pii/S026322412500497X

---

## Highlights

- Propose an automatic detection method using depth ratio features and point cloud techniques to identify wear marks and calculate geometric features of honeycomb sealing rings, even in noisy conditions.
- A least-squares iterative method is developed to fit a reference line, eliminating the errors caused by the laser beam's deviation from perfect perpendicularity to the honeycomb surface due to uneven ground or environmental vibrations.
- A depth ratio feature extraction method is developed, combined with the AMPD algorithm for detection. Furthermore, a masking mechanism is introduced to address the AMPD algorithm's sensitivity towards defects with varying lengths, thereby enhancing the detection algorithm's robustness.

---

## Abstract

The wear conditions of honeycomb sealing rings in aerospace engines are often complex. Traditional human operations based on sample paste exhibit poor adaptability and are inefficient. This paper proposes an automated detection method for the geometric features of wear marks on honeycomb sealing structures based on depth ratio features. Adaptive identification and quantification of cellular wear through point cloud data analysis. First, the point cloud data is cropped, followed by a least-squares fit iterative method to compute a reference line at a specified cross-section, which serves as a standard for computing the width and depth of wear marks while denoising the point cloud data. Subsequently, N-neighborhood sets and the depth ratio features within these sets are introduced, transforming the task of detecting wear marks' start and end points into a peak detection problem. An improved automatic multiscale-based peak detection (AMPD) algorithm with a masking mechanism is utilized to determine the extent of each wear mark. Finally, the geometric features are calculated for each wear mark. Experimental results demonstrate that the proposed method can robustly identify wear areas with varying depths and distributions, measurement time reduced by more than 90%, and fulfilling the requirements for identifying and measuring honeycomb wear marks.

---

## Keywords

- Honeycomb − labyrinth seal
- Wear mark recognition
- Depth ratio feature
- AMPD
- Mask mechanism

---

## Introduction

Sealing technology in aerospace engines refers to the effective sealing techniques used between engine components or between the engine and the external environment. Establishing stable and efficient sealing technology plays a pivotal role in enhancing the performance and reliability of aerospace engines. First, sealing technology protects internal mechanical components. It ensures that fuels, air, lubricants, and other fluids do not leak or contaminate the engine while preventing external substances from entering and damaging critical internal components. Second, sealing technology reduces fuel consumption and improves engine efficiency. Li et al. [1] conducted the research and indicated that a 1 % increase in the clearance between compressor blade tips and casing can lead to a 1 % to 3 % decrease in compressor efficiency. Chen et al. [2] found that for a turbine with a diameter of approximately 1 m, increasing the tip clearance from 1 mm to 5 mm can result in a 10 % increase in fuel consumption. Finally, effective sealing reduces mechanical wear and corrosion, prolonging the engine's service life and reducing unnecessary maintenance costs.

The emergence of metal sealing rings represents a significant advancement in sealing technology. Currently, the commonly used forms of metal sealing rings mainly include metal gaskets, O-rings, C-rings and Ω-rings as shown in Fig. 1. Among these, the O-ring labyrinth sealing technology is the most widely utilized in aerospace engines, primarily utilized to prevent fluid leakage between high and low-pressure chambers. The physical picture of the part is shown in Fig. 2. This sealing device mainly consists of a wheel, drum, shaft, blade crown, circumferential labyrinth sealing on rotating components, and the annular cylindrical surface on stationary components. To minimize leakage during the design of the labyrinth sealing structure, the stationary bushing is designed with a wear-resistant honeycomb structure. Various structural designs have been developed based on the O-rings, including labyrinth-hexagonal honeycomb seals, labyrinth-square honeycomb seals, and labyrinth-circular honeycomb seals [3]. At first, O-rings were made of rubber [24], but as sealing requirements increased, metal O-rings gradually developed. At present, Hastelloy-X high-temperature alloy with a thickness of 0.05–0.10 mm is widely used to make hexagonal honeycomb on the surface of honeycomb sealing rings.

Under high-speed operating conditions, labyrinth and sealing rings experience wear and develop scratches [4]. The wear occurs unevenly in the axial and circumferential directions, with touchpoints shifting in front of the labyrinth's cold state position. After 600 h of testing, the sealing gap wear stabilizes, with the deepest wear groove reaching approximately 0.7 mm and the widest at about 4 mm [1], [5]. Multiple factors, such as load, operating speed, dynamic and thermodynamic effects, lubrication conditions, and material properties, influence the entire wear process magnitude, making accurate prediction and control challenging. Detecting the wear conditions of the honeycomb sealing ring can provide valuable data support for maintenance evaluation. The geometrical parameters of wear marks reflect changes in the radial gap and axial displacement positions between the labyrinth and sealing ring during engine operation, allowing for the analysis of rotor vibration patterns. Therefore, investigating intelligent measurement and evaluation techniques for assessing the geometrical characteristics of honeycomb sealing ring wear marks holds scientific and engineering importance.

Due to the unique structure of honeycomb seals, it is infeasible to utilize measurement tools such as calipers directly [6]. Traditional manual measurement techniques combine impression paste and video measurement systems to obtain dimensions [7]. After the engine is disassembled, samples are taken from the sealing ring inner side's honeycomb wear grooves using a patterning compound. After cutting off the surface of the patterning compound corresponding to the honeycomb lattice protrusions, the sample is cut along the axis and then measured using an image measuring instrument. This method is inefficient and may damage the original structure. A large amount of patterning compound is required for each measurement, resulting in high material costs. Sampling requires waiting for the patterning compound to set, which takes a long time for measurement. Additionally, it is highly dependent on the skills and experience of the professional personnel, making it easy to leave difficult-to-remove residual compound in the honeycomb holes. Two categories of measurement methods have been developed: contact and non-contact methods. Contact measurements utilize coordinate measuring machines. However, if the probe becomes lodged in the honeycomb holes or fails to contact the deepest point of the wear mark, accurate measurement of the deepest position cannot be achieved. Non-contact measurement methods [8], such as optical scanning and X-ray detection, could reduce the complexity of manual operation. By observing the relative position changes between the sealing teeth tip and the sealing ring during the engine test run, the outer contour of the sealing teeth tip's relative motion trajectory with respect to the sealing ring can be obtained. Combining the cold-state measurement data of the inter-tooth gap, the shape of the wear groove on the sealing ring can be determined. However, the cost of X-ray measurement equipment is very high, and it directly measures the displacement of the parts. The shape of the wear groove needs to be determined through complex analysis after the measurement.

With the advancements in visual measurement technologies and data processing methods, such as computer vision and deep learning, utilizing point cloud data for measurements in complex scenarios is progressively becoming a novel approach with enhanced precision and efficiency [9]. The point cloud denoising and processing algorithms have been developed with feature extraction and computation advancements, facilitating rapid and robust identification of wear mark features and efficient data processing. This paper addresses the measurement of honeycomb wear marks, particularly the challenges in extracting wear mark boundary points, by proposing a method that combines deep ratio features with automatic multi-scale peak detection for the efficient and automated extraction of geometric features of wear marks.

---

## Methodology

The overall approach of this study is as follows: Firstly, a specialized point cloud acquisition equipment is designed to capture the characteristics of the sealing ring component (Section 2.1). After obtaining the point cloud data, the transverse cross-sectional lines are extracted for computational analysis. To mitigate the errors in point cloud data caused by the device's imperfect horizontal alignment, a least-squares fit iterative method is developed to compute the unworn cross-section.

---

## Experiment

To validate the proposed algorithm's applicability across different scratches and the accuracy of scratch extraction, this study selected an old honeycomb sealing ring from a combustion chamber of a specific engine at the Shanghai LinGang base of the Commercial Aero Engine Co., Ltd. of China Aerospace. On-site measurements evaluated the wear condition of the honeycomb sealing ring. Eight positions were uniformly selected along the circumference, with one point as the reference origin.

---

## Conclusion

This paper proposes an automatic detection method based on the depth ratio feature, integrating point cloud techniques to achieve automatic identification and geometric feature calculation of honeycomb sealing rings' wear marks, even in noise disturbances. Three primary results are obtained and summarized below.

1. A laser scanning-based point cloud data acquisition system is developed for honeycomb sealing rings, capitalizing on the advantages of laser scanning technology, such as exceptional...

---

## CRediT Authorship Contribution Statement

- **Tianchen Cao:** Writing – original draft, Methodology, Conceptualization.
- **Dongbo Wu:** Writing – review & editing, Methodology.
- **Huiling Li:** Writing – review & editing.
- **Xueping Liu:** Software, Resources.
- **Hui Wang:** Writing – review & editing, Data curation, Conceptualization.

---

## Declaration of Competing Interest

The authors declare that they have no known competing financial interests or personal relationships that could have appeared to influence the work reported in this paper.

---

## Acknowledgments

The author would like to acknowledge the support and contributions of our colleagues at AVIC Chengdu Engine Co., Ltd and AECC Aviation Power Co., Ltd. This article is supported by the key project of Industry-University-Research cooperation funded by the Aviation Engine Corporation of China (Project No. HFZL2023CXY025).

---

## References

1. R.F. Salant, "Progress Towards a Realistic Numerical Model for Eastover Reciprocating Seals," *Sealing Tech*, 2007.
2. L. Na et al., "Analysis on the variation law of sealing clearance in engine working state based on the measured data of honeycomb rub-grooves," *Aviation Maintenance & Engineering*, 2022.
3. L.S. Chen et al., "Development of study and application of aeroengine sealing technology," *Aeronautical Manufacturing Technology*, 2008.
4. He Z P, Wang Y B, Wang W T, et al., "Effect of Honeycomb Structure on Sealing Performance of Labyrinth-Honeycomb Seal."
5. N. Zhang et al., "Investigation of high-speed rubbing behavior of labyrinth-honeycomb seal for turbine engine application," *J. Zhejiang Univ.-Sci. A*, 2016.
6. Q. Mai et al., "The wear fault analysis of labyrinth seals for a certain type of aero-engine," *Scientific and Technological Innovation*, 2023.
7. C. Baofeng et al., "The invention relates to a measuring device and method for honeycomb abrasion depth," China Patent, 2019.
8. W. Xiaoyan et al., "A method for measuring geometrical parameters of wear marks of honeycomb sealing device," China Patent, 2023.
9. Z. Qing et al., "A data correction method for obtaining the gap between honeycomb structures using high-energy X-rays," China Patent, 2022.
10. Z. Cheng, "Automatic Measurement of Wear Mark Based on Image Processing," 2017.
11. "Pedometer method based on adaptive peak detection algorithm," *J. Chin. Inert. Technol*, 2015.
12. "Improved inverse distance weighting interpolation algorithm for peak detection," *Infrared and Laser Engineering*, 2013.

---

*Persistent link using digital object identifier (DOI)*
