drop table if exists fl_pub;
create table fl_pub (
  id integer primary key autoincrement,
  pub_date string not null,
  git string not null,
  run_name string not null,
  apps_name string not null,
  tag string not null,
  env string not null,
  server string not null,
  port string not null
);