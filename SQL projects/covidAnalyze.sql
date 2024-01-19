-- Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths
-- Show the likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE location like '%Canada%' and total_cases IS NOT NULL
ORDER BY 1,2;

-- Looking at the total cases vs Population
-- Show what percentage of population got covid
SELECT location, date, total_cases, population, (total_cases / population)*100 AS casePercentage
FROM CovidDeaths
WHERE total_cases IS NOT NULL AND location LIKE 'Canada'
ORDER BY 2;

-- Looking at country with highest infection rate compare to population at the last date
SELECT location, date, population, total_cases, (total_cases / population)*100 AS casesPercentage
FROM CovidDeaths
WHERE date = (SELECT MAX(date) FROM CovidDeaths) AND total_cases IS NOT NULL
ORDER BY casesPercentage DESC;

-- Show the countries with highest Death Count per Population
SELECT location, population, MAX(CAST(total_deaths AS int)) as total_deaths, MAX(CAST(total_deaths as int) / population)*100 AS deathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY deathPercentage DESC;

-- Let's break things down by continent with death Count per Population
SELECT continent, SUM(population) as totalPopulation, 
		SUM(CAST(total_deaths AS INT)) as totalDeaths, 
		SUM(CAST(total_deaths AS INT)) / SUM(population)*100 AS totalDeath
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY totalDeaths DESC;


-- Looking at Population vs Vaccination
WITH popVsVac(continent, location, date, population, newVaccinations, accumulatedVac)
AS (
SELECT dea.continent, dea.location, dea.date, population, new_vaccinations,
	SUM(CONVERT(INT,new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS total_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.population is not null
	AND dea.location = 'Canada'
)
SELECT location, MAX(population), max(newVaccinations), MAX(accumulatedVac), (MAX(accumulatedVac / population))*100 AS accumulatedPercentage 
FROM popVsVac
GROUP BY location

-- Create view to store data for later visualization
CREATE VIEW AccumatedVaccination AS
SELECT dea.continent, dea.location, dea.date, population, new_vaccinations,
	SUM(CONVERT(INT,new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS total_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.population is not null