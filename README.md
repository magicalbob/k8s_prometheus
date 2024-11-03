# Prometheus Kubernetes Installation

This project automates the installation of Prometheus on a Kubernetes cluster using a script. It sets up a local Kubernetes environment using Kind (Kubernetes in Docker) if no existing cluster is available, and deploys Prometheus along with the necessary configuration and persistent storage.

## Prerequisites

Before running the installation script, ensure that you have the following installed:

- **Docker**: Required for running the Kind cluster.
- **kubectl**: Command-line tool for interacting with Kubernetes.
- **kind**: Tool for running local Kubernetes clusters.

## License

This project is licensed under the GNU General Public License Version 3. See the `LICENSE` file for details.

## Files Included

- `install-prometheus.sh`: Bash script to automate the installation of Prometheus on Kubernetes.
- `kind-config.yaml`: Kind configuration file defining the Kubernetes cluster settings.
- `local-storage-class.yml`: Kubernetes StorageClass definition for local storage.
- `prometheus.svc.yml`: Service definition for Prometheus.
- `prometheus.yml`: Deployment definition for Prometheus, including its containers and persistent volume claim.
- `LICENSE`: The GNU General Public License Version 3.

## Installation

To install Prometheus on your Kubernetes cluster, follow these steps:

1. **Clone this repository** or navigate to the directory containing the project files.

2. **Run the installation script**:

   ```bash
   chmod +x install-prometheus.sh
   ./install-prometheus.sh
   ```

   The script will check for the availability of `kubectl`. If it can't find any Kubernetes cluster, it will create one using Kind and deploy Prometheus.

3. **Verify the installation**:
   
   After the script completes, you can check the status of the Prometheus deployment by running:

   ```bash
   kubectl get all -n prometheus
   ```

   You should see the Prometheus pods, services, and other resources listed.

## Accessing Prometheus

Prometheus will be accessible within the cluster. You can set up port forwarding to access the Prometheus web interface locally using:

```bash
kubectl port-forward svc/prometheus -n prometheus 9090:9090
```

Then, open your browser and navigate to [http://localhost:9090](http://localhost:9090).

## Notes

- Make sure that the paths specified in `kind-config.yaml` match your local environment, especially for storage management.
- Modify the `prometheus.yml` file as necessary to customize Prometheus settings.
- Ensure that you have the necessary permissions in the Kubernetes cluster to create namespaces, persistent volumes, and deployments.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request (PR) or open an issue if you have suggestions or improvements.

## Support

For issues related to this project, please open an issue in the repository.
