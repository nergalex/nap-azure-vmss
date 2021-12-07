NGINX App Protect + Controller | Life Cycle Management
##############################################################

NGINX Controller offers a simplified Life Cycle Management of your NGINX instances across all of your environment:
- **Auto Scaling**: during Scale In / Scale Out, the instance register / unregister to NGINX Controller
- **Upgrade**: Use the native feature ``rolling upgrade`` of your Cloud Service Provider
- **Source Of Truth**: a NGINX instance is bootstrapped from a standard Linux VM image, all of configurations are pushed from NGINX Controller

This repo provides an implementation of a scaling group of NGINX App Protect instances managed by NGINX Controller.
This implementation is Cloud agnostic, same onboarding principles and scripts are reusable on any Cloud (Private, Public).
InfraOps are free to use the scaling policy offered by their Cloud Service Provider (CSP).

.. contents:: Contents
    :local:

Pre-Requisites
*****************************************
- NGINX Controller:
    - hosted on a "Cross Management" / "Shared service" / "Out of Band" zone
    - provisioned with an empty Instance Group and Location
    - Services can be already attached on this Instance Group. For example on another Region or CSP

- VM Scale Set is created with 2 Network Interfaces Cards:
    - Management Plane (eth0)
    - Data Plane (eth1) with its Primary IP as a pool member of an Azure External Load Balancer

.. image:: ./_pictures/architecture.png
   :align: center
   :width: 1000
   :alt: Architecture

Onboarding
*****************************************
After the bootstrapping phase of a VM image,
CentOS in this example,
the next phase is to onboard it using a Shell or a Cloud Init script that includes the 2 scripts below.
For example see the Extension `here <https://github.com/nergalex/nap-azure-vmss/blob/master/_files/nginx_managed_by_controller_bootstrapping.jinja2>`_ in Jinja2 format for Ansible

1. Install packages
=========================================
`install_managed_nap.sh <https://github.com/nergalex/nap-azure-vmss/blob/master/install_managed_nap.sh>`_ install then run:
- NGINX+: Application Load-Balancer
- App Protect module: Web Application and API Protection
- last WAF signature update
- NGINX Controller agent: register VM instance and pull configuration

Input variables:

=====================================================  =======================================================================================================
Variable                                               Description
=====================================================  =======================================================================================================
``EXTRA_NGINX_CONTROLLER_IP``                          NGINX Controller IP
``EXTRA_NGINX_CONTROLLER_USERNAME``                    NGINX Controller user account
``EXTRA_NGINX_CONTROLLER_PASSWORD``                    NGINX Controller user password
``EXTRA_NGINX_PLUS_VERSION``                           NGINX+ version to install
``EXTRA_LOCATION``                                     Location name, same as created on NGINX Controller
``EXTRA_VMSS_NAME``                                    VM Scale Set name, same as the Instance Group created on NGINX Controller
=====================================================  =======================================================================================================

2. Monitor Scale In event
=========================================
`launch_monitor.sh <https://github.com/nergalex/nap-azure-vmss/blob/master/scale_in_monitor.sh>`_ monitors a Scale In event.
When a Scale In occurs, this script is responsible to unregister this instance from NGINX Controller

Input variables:

=====================================================  =======================================================================================================
Variable                                               Description
=====================================================  =======================================================================================================
``ENV_CONTROLLER_USERNAME``                            NGINX Controller user account with less privilege on Instance Group
``ENV_CONTROLLER_PASSWORD``                            NGINX Controller user password
=====================================================  =======================================================================================================

Demo
*****************************************
Demo done on Azure using a VM Scale Set.

Scale Out
=========================================

.. raw:: html

    <a href="http://www.youtube.com/watch?v=BMEK_JEi3cc"><img src="http://img.youtube.com/vi/BMEK_JEi3cc/0.jpg" width="600" height="400" title="Create Identity Provider" alt="Create Identity Provider"></a>


Scale In
=========================================

.. raw:: html

    <a href="http://www.youtube.com/watch?v=BMEK_JEi3cc"><img src="http://img.youtube.com/vi/BMEK_JEi3cc/0.jpg" width="600" height="400" title="Create Identity Provider" alt="Create Identity Provider"></a>

Upgrade
=========================================

.. raw:: html

    <a href="http://www.youtube.com/watch?v=BMEK_JEi3cc"><img src="http://img.youtube.com/vi/BMEK_JEi3cc/0.jpg" width="600" height="400" title="Create Identity Provider" alt="Create Identity Provider"></a>
