-- Exploratory Data Analysis (EDA)
SELECT * 
FROM layoffs_staging2;

-- to see the period of time
SELECT MIN(date), MAX(date)
FROM layoffs_staging2;

-- to see how big these layoffs were
SELECT MAX(percentage_laid_off),  MIN(percentage_laid_off)
FROM layoffs_staging2
WHERE  percentage_laid_off IS NOT NULL;

-- ordered by funds_raised_millions to see how big some of these companies were
SELECT *
FROM layoffs_staging2
WHERE  percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- 5 biggest companies with single layoff (in a single day)
SELECT company, total_laid_off
FROM layoffs_staging
ORDER BY 2 DESC
LIMIT 5;

-- 10 companies with the overall most total layoffs
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;

-- a temp table to identify companies with more than 5000 layoffs
DROP TEMPORARY TABLE IF EXISTS HighLayoffCompanies;
CREATE TEMPORARY TABLE HighLayoffCompanies AS
SELECT company, industry, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY company, industry
HAVING total_layoffs > 5000;

SELECT * FROM HighLayoffCompanies;

-- top 5 companies with the most layoffs for each year
WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS 
(
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT *
FROM Company_Year_Rank
WHERE ranking <= 5
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;

-- total layoffs in the past 3 years by country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- total layoffs by year
SELECT YEAR(date), SUM(total_laid_off)
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY YEAR(date)
ORDER BY 1 ASC;

-- industries with highest average percentage of layoffs
SELECT industry, ROUND(AVG(percentage_laid_off),3) AS average_percentage_laid_off
FROM layoffs_staging2
WHERE industry IS NOT NULL
GROUP BY industry
ORDER BY 2 DESC;

-- rolling total of layoffs per month
WITH DATE_CTE AS 
(
SELECT SUBSTRING(`date`,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, total_laid_off, 
		SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM DATE_CTE
WHERE dates IS NOT NULL
ORDER BY dates ASC;

-- creating view to store industry layoff trends for easy visualization
CREATE VIEW industry_layoff_trends AS
SELECT industry, YEAR(date) , SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE industry IS NOT NULL
GROUP BY industry, YEAR(date);

SELECT * FROM industry_layoff_trends;


















































