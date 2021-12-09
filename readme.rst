NGINX Controller makes Life Cycle Management simple
##############################################################

NGINX Controller offers a simplified **Life Cycle Management** of your NGINX instances across all of your environment:

- **Auto Scaling**
    during Scale In / Scale Out, the instance register / unregister to NGINX Controller
- **Up to date OS, software and Security signatures**
    use the native feature ``reimage`` or ``rolling upgrade`` of your Cloud Service Provider
- **Source Of Truth**
    a NGINX instance is bootstrapped from a standard Linux VM image, all of configurations are pushed from NGINX Controller
- **Cloud agnostic**
    same principles and onboarding scripts are reusable on any Cloud (Private, Public)
- **Native Scaling Policy**
    InfraOps are free to use the scaling policy offered by their Cloud Service Provider (CSP).

This repo provides an implementation of a scaling group of NGINX App Protect instances managed by NGINX Controller.

--------------------------------------------------------------------------------------------------------------------

.. contents:: Contents
    :local:

Mutable vs Immutable
*****************************************

When an new VM instance is bootstraped, this instance is up to date:

    - **OS** packages
    - **Software**: NGINX Plus, NGINX App Protect and NGINX Controller agent
    - **Security** signatures

Then this instance retrieve his configuration from NGINX Controller.
Therefore NGINX Controller is the *Source of Truth* for all of your managed NGINX instances.

In order to upgrade your cluster, the *immutable* approach is recommended: destroy & recreate your VM instances.
As done on **Kubernetes**, the *immutable* approach is more simpler and safer than the mutable approach that will apply changes.

How to do that on Azure VM Scale Set?

Immutable = Reimage
=========================================
If you select ``reimage``,
it will remove the VMSS instance and replace it with a brand new one.
This can be used if you are having issues or need to upgrade per instance, that will **delete it and redeploy it up to date**.

Mutable = Upgrade
=========================================
Upgrading will **apply any changes** that were applied to the scaleset as a whole.
So for example, if you apply a custom script extension to VMSS1 you need to update the VMSS instances in order for that custom script to actually be applied.

Solution to do not impact User Experience during a Scale In or reimage operation
================================================================================
During a *Scale In* or *reimage* operation,
an impact on User Experience exists if:

    - **persistency** is set on the downstream Load Balancer
    - **no Global Load Balancing** exists across regions or multi-cloud.

Symptom
*****************************************
A user or a consumer have no access to the service during few seconds with no notification

Cause
*****************************************
A Web Browser opens up to 15 TCP sessions to a remote Domain service
and keep it them alive in order to re-use then to send further HTTP transactions.
When a ``Scale In`` or ``reimage`` operation occurs, NGINX process received a SIG_TERM signal and all of NGINX workers (1 per vCPU) shutdown gracefully: current HTTP transactions are drained and then TCP sessions closed:

As shown in the video `here <https://github.com/nergalex/nap-azure-vmss#upgrade-reimage>`_ , a Wireshark captures on the user's PC.
The picture below shows a ``reimage`` operation that occured at second #7.

.. image:: ./_pictures/capture_nginx_drain.png
   :align: center
   :width: 800
   :alt: NGINX drains transactions

However, the External Azure Load Balancer is configured with:
    - a `Persistency <https://docs.microsoft.com/en-us/azure/load-balancer/distribution-mode-concepts>`_
    - a health probe interval of 5s
    - a unhealthy threshold of 2
In that case, further TCP session initiated by the browser will be stuck up to 15s to the same VM instance... that is down.

.. image:: ./_pictures/capture_persist.png
   :align: center
   :width: 800
   :alt: ALB persists

After 15s, External Azure Load Balancer chose another pool member. Then the service is up again for this user.

Solution
*****************************************

1. **DNS Load Balancing**. Load-Balance traffic across 2 regions or multi-cloud. 2 Public IPs are returned during DNS resolution. If a TCP session on one Public IP returns a RST, Web Browser will switch automatically to the other Public IP. No impact on User Experience, well done! :o)
2. Do not persist? **No**, it's not a solution, persistency is useful for troubleshooting purpose and Web Application Firewall security features that track user sessions (CSRF, DeviceID, JS injection, cookie...).


Pre-Requisites
*****************************************
- NGINX Controller:
    - hosted on a "Cross Management" / "Shared service" / "Out of Band" zone
    - provisioned with an empty Instance Group and Location
    - Services can be already attached on this Instance Group. For example on another Region or CSP

- VM Scale Set. A CentOS image is used in this example.

.. image:: ./_pictures/architecture.png
   :align: center
   :width: 1000
   :alt: Architecture

Onboarding
*****************************************
Once the VM is started, the VM is onboarded with the script specified as an Extension.
It could be a Shell or a Cloud Init script that must includes the 2 scripts below.

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
`scale_in_monitor.sh <https://github.com/nergalex/nap-azure-vmss/blob/master/scale_in_monitor.sh>`_ monitors a Scale In event.
When a Scale In occurs, this script is responsible to unregister this instance from NGINX Controller

Input variables:

=====================================================  =======================================================================================================
Variable                                               Description
=====================================================  =======================================================================================================
``ENV_CONTROLLER_USERNAME``                            NGINX Controller user account with less privilege on Instance Group
``ENV_CONTROLLER_PASSWORD``                            NGINX Controller user password
=====================================================  =======================================================================================================

Demo video
*****************************************
Demo done on Azure using a VM Scale Set.

Scale Out
=========================================

.. raw:: html

    <a href="http://www.youtube.com/watch?v=Ol4CCxI0uVY"><img src="http://img.youtube.com/vi/Ol4CCxI0uVY/0.jpg" width="600" height="400" title="VMSS + NGINX Controller | Scale Out" alt="VMSS + NGINX Controller | Scale Out"></a>

Scale In
=========================================

.. raw:: html

    <a href="http://www.youtube.com/watch?v=P005gt9eAg0"><img src="http://img.youtube.com/vi/P005gt9eAg0/0.jpg" width="600" height="400" title="VMSS + NGINX Controller | Scale In" alt="VMSS + NGINX Controller | Scale In"></a>

Upgrade / Reimage
=========================================

.. raw:: html

    <a href="http://www.youtube.com/watch?v=Zr8UBIC-UHw"><img src="http://img.youtube.com/vi/Zr8UBIC-UHw/0.jpg" width="600" height="400" title="VMSS + NGINX Controller | Reimage" alt="VMSS + NGINX Controller | Reimage"></a>
