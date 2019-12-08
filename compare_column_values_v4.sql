drop procedure compare_column_values;

-- what is in both wk and froz
go
create procedure compare_column_values(@db1 varchar(100), @t1 varchar(100), @pk1 varchar(100), @db2 varchar(100), @t2 varchar(100), @pk2 varchar(100))
as

declare @sel nvarchar(max);

select * into #shared_columns from (select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME='-1') AS T;

set @sel = 'Insert
into #shared_columns
select * from
(select COLUMN_NAME
from '+@db1+'.INFORMATION_SCHEMA.COLUMNS
where TABLE_CATALOG='''+@db1+''' and
TABLE_NAME = ''' + @t1 + '''

intersect

select COLUMN_NAME 
from '+@db2+'.INFORMATION_SCHEMA.COLUMNS
where TABLE_CATALOG='''+@db2+''' and
TABLE_NAME = ''' + @t2 + ''') as t;';

exec sp_executesql @sel;

-- ----------------------------------------------------------------------------

-- select * from #shared_columns; -- < column names

-- cursor:
-- column string
-- select C.column, A.column as @t1, B.clumn as @t2 from @t1 A, @t2 B, #shrd_cols C where @t1.column=@t2.column and c.columname=column

-- -----------------------------------------------------------------------------

declare @query nvarchar(max);
declare @colname nvarchar(50);


create table #temp
(
	column_name varchar(max),
	differences bigint,
	source_table varchar(max) default 'both'
);

-- differences
declare shrcol_cursor cursor
for select * from #shared_columns;

open shrcol_cursor;

fetch next from shrcol_cursor into @colname;
set @query = 'insert into #temp (column_name, differences) select column_name, count(column_name) as differences from (select '''+@colname+''' as column_name, A.'+@colname+' as '+@t1+', B.'+@colname+' as '+@t2+' from '+@db1+'.dbo.'+@t1+' as A, '+@db2+'.dbo.'+@t2+' as B where A.'+@pk1+'=B.'+@pk2+') as t where '+@t1+'<>'+@t2+' or ('+@t1+' is null and '+@t2+' is not null) or ('+@t2+' is null and '+@t1+' is not null) group by column_name';
exec sp_executesql @query;

while @@FETCH_STATUS = 0
Begin

	fetch next from shrcol_cursor into @colname;
	set @query = 'insert into #temp (column_name, differences) select column_name, count(column_name) as differences from (select '''+@colname+''' as column_name, A.'+@colname+' as '+@t1+', B.'+@colname+' as '+@t2+' from '+@db1+'.dbo.'+@t1+' as A, '+@db2+'.dbo.'+@t2+' as B where A.'+@pk1+'=B.'+@pk2+') as t where '+@t1+'<>'+@t2+' or ('+@t1+' is null and '+@t2+' is not null) or ('+@t2+' is null and '+@t1+' is not null) group by column_name';
	exec sp_executesql @query;
	
end;
close shrcol_cursor;
deallocate shrcol_cursor;

insert into #temp (column_name, differences) select column_name, 0 as differences from #shared_columns where COLUMN_NAME not in (select COLUMN_NAME from #temp);

-- columns not in both
set @sel = 'insert into #temp select column_name, null as differences, '''+@t1+''' as source_table from

(select COLUMN_NAME
from '+@db1+'.INFORMATION_SCHEMA.COLUMNS
where TABLE_CATALOG='''+@db1+''' and
TABLE_NAME = '''+@t1+''') as t

where t.COLUMN_NAME not in (select COLUMN_NAME from #temp);';

exec sp_executesql @sel;

set @sel = 'insert into #temp select column_name, null as differences, '''+@t2+''' as source_table from

(select COLUMN_NAME
from '+@db2+'.INFORMATION_SCHEMA.COLUMNS
where TABLE_CATALOG='''+@db2+''' and
TABLE_NAME = '''+@t2+''') as t

where t.COLUMN_NAME not in (select COLUMN_NAME from #temp);';

exec sp_executesql @sel;

select * from #temp;

