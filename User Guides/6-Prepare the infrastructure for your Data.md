Steps:
1. Stop all DataGen schedule
2. Drop AdventureWorks table in all the physical data warehouses - both loader and reader.
3. Size your data warehouse
4. Optionally override the initial setting for flip time
5. Create fact and dimension tables in all the physical data warehouses - both loader and reader.
6. Insert entries in the mapping DW-Table in the Job Manager SQL Database.