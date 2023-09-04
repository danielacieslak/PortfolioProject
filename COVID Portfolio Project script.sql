/*Covid 19 Data Exploration */

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is NOT NULL
ORDER BY location, date

--Showing probability of dying from Covid in my coutry

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as Death_Percentage
FROM CovidDeaths
WHERE location = 'Greece' AND continent is NOT NULL
ORDER BY location, date

--Showing percentage of population with Covid in my country

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

--Continents With Highest Death Rate per Population

SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent 
ORDER BY TotalDeathCount DESC

--Global Numbers of Covid Cases

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths,
SUM(CAST(new_deaths as int))/ SUM(new_cases) * 100 as DeathPercantage
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY date

--Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) 
OVER (Partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
FROM CovidDeaths d JOIN CovidVaccinations v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent is NOT NULL 
ORDER BY location, date


--USE CTE to perform Calculation on Partition By in previous query

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) 
OVER (Partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
FROM CovidDeaths d JOIN CovidVaccinations v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent is NOT NULL 
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
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) 
OVER (Partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
FROM CovidDeaths d JOIN CovidVaccinations v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent is NOT NULL

SELECT *, (RollingPeopleVaccinated/Population) * 100  FROM #PercentPopulationVaccinated

--Creating View to store data for later visualization


CREATE VIEW PercentPopulationVaccinated as
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) 
OVER (Partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
FROM CovidDeaths d JOIN CovidVaccinations v
	ON d.location = v.location AND d.date = v.date
WHERE d.continent is NOT NULL
