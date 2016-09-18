CREATE TABLE `entry_keyword` (
  entry_id bigint(20) unsigned NOT NULL,
  keyword varchar(191) COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (entry_id, keyword)
) ENGINE=InnoDB AUTO_INCREMENT=578 DEFAULT CHARSET=utf8mb4;
