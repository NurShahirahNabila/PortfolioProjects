-- Data Cleaning in SQL

-- 1. Remove duplicated data
-- 2. Standardized formats 
-- 3. Fixed null values where possible
-- 4. Delete unnecessary columns or rows

---------------------------------------------------------------------------------
-- Create staging table instead of using raw data
SELECT * 
FROM layoffs;

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT * 
FROM layoffs;

SELECT * 
FROM layoffs_staging;

---------------------------------------------------------------------------------
-- 1. Remove duplicated data
SELECT * 
FROM layoffs_staging;

-- To find if there is any duplicates
SELECT company, industry, total_laid_off, `date`,
		ROW_NUMBER() OVER (
						PARTITION BY company, location, industry, total_laid_off, `date`, stage, country, funds_raised_millions
                        ) AS row_num
FROM layoffs_staging;

-- Create a CTE
WITH duplicate_cte AS
(
SELECT company, industry, total_laid_off, `date`,
		ROW_NUMBER() OVER (
						PARTITION BY company, location, industry, total_laid_off, `date`, stage, country, funds_raised_millions
                        ) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- To confirm the data is duplicated
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Create another staging table with a row number column because the duplicates cannot be deleted directly from CTE before
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
		ROW_NUMBER() OVER (
						PARTITION BY company, location, industry, total_laid_off, `date`, stage, country, funds_raised_millions
                        )
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2;

-- Delete duplicates
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- To confirm that the duplicate has been deleted
SELECT *
FROM layoffs_staging2
WHERE company = 'Casper';

---------------------------------------------------------------------------------
-- 2. Standardized formats 

SELECT DISTINCT company 
FROM layoffs_staging2;
-- There are companies that start with a blank space 

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;
-- All locations are already in standardized format

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;
-- Need to standardize that Crypto and Crypto Currency are the same

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;
-- Need to standardize that United States and United States. are the same

UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
-- To convert data type from string to date

---------------------------------------------------------------------------------
-- 3. Fixed null values where possible

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ''; 
-- Need to set the blanks to nulls so it is easier to work with

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';
-- Airbnb is a travel industry but there are some with NULL industry

UPDATE layoffs_staging2
SET industry = 'Travel'
WHERE company = 'Airbnb';

-- Queries to populate those nulls
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';
-- Bally's was the only one without a populated row to populate this null values

---------------------------------------------------------------------------------
-- 4. Delete unnecessary columns or rows

SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
-- These data are not important and need to be deleted

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;
