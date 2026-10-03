#!/bin/bash

CALE_SCRIPTURI="/home/sas/config_new/Lev1/SASApp1/SASEnvironment/SASCode/Jobs"

at 02:00 <<EOF
/bin/bash "${CALE_SCRIPTURI}/start_sas_1_usp_refresh_rezultate_frauda_publish_v0.sh"
EOF

at 04:00 <<EOF
/bin/bash "${CALE_SCRIPTURI}/start_sas_2_usp_refresh_consum_silver_v0.sh"
EOF

at 07:00 <<EOF
/bin/bash "${CALE_SCRIPTURI}/start_sas_3_usp_refresh_informatii_de_business_publish_v0.sh"
EOF

at 09:00 <<EOF
/bin/bash "${CALE_SCRIPTURI}/start_sas_4_usp_refresh_informatii_tehnice_publish_v0.sh"
EOF

at 09:30 <<EOF
/bin/bash "${CALE_SCRIPTURI}/start_sas_5_usp_refresh_informatii_verificare_publish.sh"
EOF
