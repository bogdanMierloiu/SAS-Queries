            REFRESH DATE SAS VISUAL ANALYTICS

              Script principal de planificare
                         |
                         v
              Linux Scheduler - comanda `at`
                         |
       +-----------------+------------------+------------------+------------------+
       |                 |                  |                  |                  |
       v                 v                  v                  v                  v
     02:00             04:00              07:00              09:00              09:30
       |                 |                  |                  |                  |
       v                 v                  v                  v                  v
  start_sas_1       start_sas_2        start_sas_3        start_sas_4        start_sas_5
       |                 |                  |                  |                  |
       v                 v                  v                  v                  v
 rezultate_frauda     consum_silver      informatii         informatii         informatii
    _publish                              business            tehnice           verificare
                                           _publish           _publish           _publish
       |                 |                  |                  |                  |
       +-----------------+------------------+------------------+------------------+
                                            |
                                            v
                              PostgreSQL - sas_visual_analytics
                                            |
                                            v
                                  SAS Visual Analytics
                                      Dashboards