#!/bin/bash

export BOUNDARY_ADMIN=admin
export ORG_ID=o_Hhxr7HASd2
export AUTH_ID=ampw_H4eruw7DNY
export BOUNDARY_ADDR=https://a757c9c0-d7ab-435c-8998-2ae96fac9ada.boundary.hashicorp.cloud
export BOUNDARY_CLUSTER_ID=a757c9c0-d7ab-435c-8998-2ae96fac9ada # Managed Worker Req
# Login
echo "boundary authenticate password \
-auth-method-id=$AUTH_ID \
-login-name=$BOUNDARY_ADMIN
"
