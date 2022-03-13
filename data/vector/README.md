# DBStack Sample Vector Data

Sample data is a subset of data retrieved from the [Natural Earth](https://www.naturalearthdata.com/) dataset, which is released under a public domain license.

## sample_countries.shp

- Source File(s): `ne_10m_admin_0_countries.shp`
- CRS: `EPSG:4326`
- NE Version: 5.0.0
- Geometry: Multipolygon
- Selection Type: Expression
- Selection Detail: `"SUBREGION" = 'Southern Africa'`

## sample_populated_places_simple.geojson

- Source File(s): `ne_10m_populated_places_simple.shp`
- CRS: `EPSG:4326`
- NE Version: 5.0.0
- Geometry: Point
- Selection Type: Clip
- Selection Detail: `Clipped within sample_countries.shp`

## sample_gpkg.gpkg

- Source File(s): `ne_10m_ports.shp | ne_10m_airports.shp | ne_10m_urban_areas.shp`

### sample_gpkg - sample_ports

- CRS: `EPSG:4326`
- NE Version: 5.0.0
- Geometry: Multipoint
- Selection Type: Within distance
- Selection Detail: `Within 0.1° of sample_countries.shp`

### sample_gpkg - sample_airports

- CRS: `EPSG:4326`
- NE Version: 5.0.0
- Geometry: Point
- Selection Type: Clip
- Selection Detail: `Clipped within sample_countries.shp`

### sample_gpkg - sample_urban_areas

- CRS: `EPSG:4326`
- NE Version: 4.1.0
- Geometry: Multipolygon
- Selection Type: Clip
- Selection Detail: `Clipped within sample_countries.shp`
