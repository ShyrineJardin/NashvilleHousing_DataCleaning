-- Cleaning Data in Nashville Housing ---

-- making a table duplicate
SELECT *
FROM `nashville housing data for data cleaning`;

CREATE TABLE nashvillehousing_datacleaning
LIKE `nashville housing data for data cleaning`; 

INSERT nashvillehousing_datacleaning
SELECT *
FROM `nashville housing data for data cleaning`;

-- Standardize Date Format 
SELECT SaleDate
FROM nashvillehousing_datacleaning;

SELECT STR_TO_DATE(TRIM(SaleDate), '%M %d, %Y') AS CleanedSaleDate
FROM nashvillehousing_datacleaning;

UPDATE nashvillehousing_datacleaning
SET SaleDate = STR_TO_DATE(TRIM(SaleDate), '%M %d, %Y');

ALTER TABLE  nashvillehousing_datacleaning
MODIFY COLUMN SaleDate DATE;

-- Populate Property Address data
SELECT PropertyAddress,ParcelID
FROM nashvillehousing_datacleaning
WHERE PropertyAddress is null OR PropertyAddress = '';

UPDATE nashvillehousing_datacleaning
SET PropertyAddress = NULL
WHERE PropertyAddress = '';

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM nashvillehousing_datacleaning a
JOIN nashvillehousing_datacleaning b
	ON a.ParcelID = b.ParcelID
WHERE a.PropertyAddress is null;

UPDATE nashvillehousing_datacleaning a
JOIN nashvillehousing_datacleaning b
	ON a.ParcelID = b.ParcelID
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress IS NULL
AND b.PropertyAddress IS NOT NULL;

-- Breaking out Address Into Individual Columns (address, City, State)

SELECT *
FROM nashvillehousing_datacleaning;

SELECT 
    SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1) AS Address,  -- Extract text before the comma
    SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',') + 1) AS City  -- Extract text after the comma
FROM nashvillehousing_datacleaning;

ALTER TABLE nashvillehousing_datacleaning
ADD PropertySplitAddress Varchar(255);

UPDATE  nashvillehousing_datacleaning
SET PropertySplitAddress =SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1); -- -1  deletes the comma at the end of the word

ALTER TABLE nashvillehousing_datacleaning
ADD PropertySplitCity Varchar(255);

UPDATE  nashvillehousing_datacleaning
SET PropertySplitCity = SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',') + 1);

-- For Owners Address
SELECT OwnerAddress
FROM nashvillehousing_datacleaning;
 
SELECT 
    SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Part1, -- Get the first part before the first comma
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS Part2, -- Get the second part between the first and second comma
    SUBSTRING_INDEX(OwnerAddress, ',', -1) AS Part3 -- Get the last part after the last comma
FROM nashvillehousing_datacleaning;

ALTER TABLE nashvillehousing_datacleaning
ADD OwnerSplitAddress Varchar(255);

UPDATE nashvillehousing_datacleaning
SET OwnerSplitAddress =  SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE  nashvillehousing_datacleaning
ADD OwnerSplitCity Varchar(255);

UPDATE nashvillehousing_datacleaning
SET OwnerSplitCity =   SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE nashvillehousing_datacleaning
ADD OwnerSplitState Varchar(255);

UPDATE nashvillehousing_datacleaning
SET OwnerSplitState =  SUBSTRING_INDEX(OwnerAddress, ',', -1);

SELECT *
FROM nashvillehousing_datacleaning;

-- Change Y and N to Yes and NO in 'Sold as Vacant'Field
SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM nashvillehousing_datacleaning
GROUP BY SoldAsVacant
Order by 2;


SELECT SoldAsVacant,
    CASE 
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS TransformedSoldAsVacant
FROM nashvillehousing_datacleaning;

UPDATE nashvillehousing_datacleaning
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

-- Check/Remove Duplicates 
WITH duplicate_cte AS(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY UniqueID, ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice, LegalReference, SoldAsVacant, OwnerName,OwnerAddress, Acreage, TaxDistrict, LandValue) AS row_num
FROM nashvillehousing_datacleaning
)

SELECT *
FROM duplicate_cte
WHERE row_num > 1; -- no duplicates

-- Delete Unused Columns
SELECT *
FROM nashvillehousing_datacleaning;

ALTER TABLE nashvillehousing_datacleaning
DROP COLUMN OwnerAddress;

ALTER TABLE nashvillehousing_datacleaning
DROP COLUMN PropertyAddress;

ALTER TABLE nashvillehousing_datacleaning
DROP COLUMN TaxDistrict;

ALTER TABLE nashvillehousing_datacleaning
DROP COLUMN SaleDate;