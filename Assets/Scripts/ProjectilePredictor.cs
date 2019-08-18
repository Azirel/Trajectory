using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ProjectilePredictor : MonoBehaviour
{
	public GameObject PredictionBallPrefab;
	public Vector3 TrajectoryFarAwayPosition = new Vector3(-9999, -9999, -9999);
	public LineRenderer TrajectoryRenderer;
	[Range(0, 10)] public float PositionTreshold = 1;
	[Range(0, 10)] public float EulersTreshold = 1;
	[Range(0, 500)] public int TrajectoryPresicionMax;
	[Range(0, 100)] public int TrajectoryPresicionStep;
	[Range(0, 10)] public float TrajectoryPhysicsTimeStepMultiplier = 1;
	public Transform Canon;
	public float Force = 1;
	protected List<Vector3> CurrentMarkPositions = new List<Vector3>();

	protected Vector3 PreviousPosition;
	protected Vector3 PreviousEulers;
	protected Scene ScenePrediction;
	protected PhysicsScene ScenePredictionPhysics;
	protected PhysicsScene SceneMainPhysics;
	protected GameObject PredictionBall;

	private void Start()
	{
		Physics.autoSimulation = false;
		SceneManager.LoadScene(1, new LoadSceneParameters(LoadSceneMode.Additive, LocalPhysicsMode.Physics3D));
		ScenePrediction = SceneManager.GetSceneByName("PredictionScene");
		ScenePredictionPhysics = SceneManager.GetSceneByName("PredictionScene").GetPhysicsScene();

		PreviousPosition = Canon.position;
		PreviousEulers = Canon.eulerAngles;

		PredictionBall = Instantiate(PredictionBallPrefab, position: Canon.position, rotation: Quaternion.identity);
		SceneManager.MoveGameObjectToScene(PredictionBall, ScenePrediction);
		PredictionBall.GetComponent<Rigidbody>().AddForce(Canon.forward.normalized * Force, ForceMode.Impulse);
	}

	private void FixedUpdate()
	{
		if (!SceneMainPhysics.IsValid())
			return;

		if (IsThresholdBreached())
		{
			CurrentMarkPositions.Clear();
			CalculatePrediction(true);
		}
		else CalculatePrediction(false);

		PreviousPosition = Canon.position;
		PreviousEulers = Canon.eulerAngles;
	}

	protected bool IsThresholdBreached()
	{
		return Mathf.Abs(Vector3.SqrMagnitude(PreviousPosition - Canon.position)) > PositionTreshold || Mathf.Abs(Vector3.SqrMagnitude(PreviousEulers - Canon.eulerAngles)) > EulersTreshold;
	}

	public void ChangePresicion(float value)
	{
		TrajectoryPresicionMax = (int)value;
	}

	public void ChangeTimeMultiplier(float value)
	{
		TrajectoryPhysicsTimeStepMultiplier = value;
	}

	[ContextMenu("CalculatePrediction")]
	private void CalculatePrediction(bool creteNewSimulation = false)
	{
		if (!SceneMainPhysics.IsValid() || !ScenePredictionPhysics.IsValid())
			return;

		if (creteNewSimulation)
		{
			if (PredictionBall != null)
				Destroy(PredictionBall);
			PredictionBall = Instantiate(PredictionBallPrefab, position: Canon.position, rotation: Quaternion.identity);
			SceneManager.MoveGameObjectToScene(PredictionBall, ScenePrediction);
			PredictionBall.GetComponent<Rigidbody>().AddForce(Canon.forward.normalized * Force, ForceMode.Impulse);
		}

		int CurrentMarksCount = CurrentMarkPositions.Count;
		for (int i = CurrentMarksCount; i < CurrentMarksCount + TrajectoryPresicionStep; i++)
		{
			if (CurrentMarkPositions.Count >= TrajectoryPresicionMax)
				break;
			ScenePredictionPhysics.Simulate(Time.fixedDeltaTime * TrajectoryPhysicsTimeStepMultiplier);
			CurrentMarkPositions.Add(PredictionBall.transform.position);
		}
		TrajectoryRenderer.positionCount = CurrentMarkPositions.Count;
		TrajectoryRenderer.SetPositions(CurrentMarkPositions.ToArray());
	}
}
