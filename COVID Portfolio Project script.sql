

--Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

---- Select Data that we are going to be starting with


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is NOT NULL
ORDER BY location, date

-- Total Cases vs Total Deaths 
-- Shows probability of daying from Covid in my coutry

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as Death_Percentage
FROM CovidDeaths
WHERE location = 'Greece' and continent is NOT NULL
ORDER BY location, date

--Total Cases vs Population
--Shows percentage of population with Covid in my country

SELECT location, date, population, total_cases, (total_cases/population) * 100 as Covid_Percentage_Infected
FROM CovidDeaths
WHERE location = 'Greece'
ORDER BY location, date

--Countries With Highest Infection Rate Compared to Population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)) * 100 as Covid_Percentage_Infected
FROM CovidDeaths
GROUP BY location, population
ORDER BY Covid_Percentage_Infected DESC

--Countries With Highest Death Rate per Population


SELECT location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--BREAING THINGS BY CONTINENT

--Continents With Highest Death Rate per Population

SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent 
ORDER BY TotalDeathCount DESC


--GLOBAL NUMBERS 

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths,
SUM(CAST(new_deaths as int))/ SUM(new_cases) * 100 as DeathPercantage
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY date

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths,
SUM(CAST(new_deaths as int))/ SUM(new_cases) * 100 as DeathPercantage
FROM CovidDeaths
WHERE continent is NOT NULL

--Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as int)) 
	OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY location, date


--USE CTE to perform Calculation on Partition By in previous query

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population) * 100 FROM PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
( 
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as int)) 
	VER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is NOT NULL

SELECT *, (RollingPeopleVaccinated/Population) * 100  FROM #PercentPopulationVaccinated

--Creating View to store data for later visualization


CREATE VIEW PercentPopulationVaccinated as
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations as int)) OVER  (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is NOT NULL
