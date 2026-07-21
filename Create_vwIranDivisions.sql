/*
    vwIranDivisions
    Flattened view of the parent-child IranDivisions table, showing each
    row's full ancestry as separate columns (Province, County, District,
    City, Village) instead of requiring a recursive query.

    NOTE: run this AFTER the IranDivisions table has been created and
    populated (see Import_IranDivisions_ParentChild.ps1).

    NOTE ON SCHEMA: this assumes the table lives in the "dbo" schema,
    matching the CREATE TABLE statement in the import script. If your
    IranDivisions table is in a different schema (e.g. "prd"), update
    both references below accordingly.
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW dbo.vwIranDivisions
AS
SELECT t.Id,
       t.[Level] AS NodeLevel,
       CASE
           WHEN t.Level = 1 THEN t.NameFa
           WHEN p1.Level = 1 THEN p1.NameFa
           WHEN p2.Level = 1 THEN p2.NameFa
           WHEN p3.Level = 1 THEN p3.NameFa
           WHEN p4.Level = 1 THEN p4.NameFa
       END AS Province,
       CASE
           WHEN t.Level = 2 THEN t.NameFa
           WHEN p1.Level = 2 THEN p1.NameFa
           WHEN p2.Level = 2 THEN p2.NameFa
           WHEN p3.Level = 2 THEN p3.NameFa
           WHEN p4.Level = 2 THEN p4.NameFa
       END AS County,
       CASE
           WHEN t.Level = 3 THEN t.NameFa
           WHEN p1.Level = 3 THEN p1.NameFa
           WHEN p2.Level = 3 THEN p2.NameFa
           WHEN p3.Level = 3 THEN p3.NameFa
           WHEN p4.Level = 3 THEN p4.NameFa
       END AS District,
       CASE
           WHEN t.Level = 4 THEN t.NameFa
           WHEN p1.Level = 4 THEN p1.NameFa
           WHEN p2.Level = 4 THEN p2.NameFa
           WHEN p3.Level = 4 THEN p3.NameFa
           WHEN p4.Level = 4 THEN p4.NameFa
       END AS City,
       CASE
           WHEN t.Level = 5 THEN t.NameFa
           WHEN p1.Level = 5 THEN p1.NameFa
           WHEN p2.Level = 5 THEN p2.NameFa
           WHEN p3.Level = 5 THEN p3.NameFa
           WHEN p4.Level = 5 THEN p4.NameFa
       END AS Village
FROM dbo.IranDivisions t
    LEFT JOIN dbo.IranDivisions p1 ON p1.Id = t.Parent
    LEFT JOIN dbo.IranDivisions p2 ON p2.Id = p1.Parent
    LEFT JOIN dbo.IranDivisions p3 ON p3.Id = p2.Parent
    LEFT JOIN dbo.IranDivisions p4 ON p4.Id = p3.Parent;
GO
