CREATE TABLE `star` (
  `entry_id` bigint(20) unsigned NOT NULL,
  `user_name` varchar(191) COLLATE utf8mb4_bin NOT NULL,
  KEY (`entry_id`, `user_name`)
) ENGINE=InnoDB AUTO_INCREMENT=65 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
