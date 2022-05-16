defmodule Smartpi.SoilMoisture do
  alias Circuits.I2C

  @minDry 18253
  @maxWet 64000

  def read_soil do
    {:ok, ref} = I2C.open("i2c-1")
    I2C.write(ref, 0x36, <<0x0F, 0x10>>)
    Process.sleep(5)
    {:ok, <<value::little-size(16)>>} = I2C.read(ref, 0x36, 2)
    I2C.close(ref)
    value
  end

  def read_soil(ntimes) do
    {:ok, ref} = I2C.open("i2c-1")

    data =
      for _ <- 0..ntimes do
        I2C.write(ref, 0x36, <<0x0F, 0x10>>)
        Process.sleep(5)
        {:ok, <<value::little-size(16)>>} = I2C.read(ref, 0x36, 2)
        value
      end
      I2C.close(ref)

    data
  end

  def read_capacity_mean(n_measurements \\ 100) do
    data = read_soil(n_measurements)
    Enum.sum(data) / length(data)
  end

  def rel_moisture(n_measurements \\ 100) do
    capacity = read_capacity_mean(n_measurements)

    rel_moisture = cond do
      capacity < @minDry -> 0
      capacity > @maxWet -> 100
      true ->
        (capacity - @minDry) / (@maxWet - @minDry)
    end

    {rel_moisture, capacity}
  end

  def get_moisture(n_measurements, address) do
    {relative_moisture, capacity} = rel_moisture(n_measurements)

    rel_moisture_sensor = relative_moisture
      |> Smartpi.Sensor.new_sensor("float", "soil", "moisture")
      |> Smartpi.Sensor.send_sensor(address)

    capacity_sensor = capacity
      |> Smartpi.Sensor.new_sensor("float", "soil", "capacity")
      |> Smartpi.Sensor.send_sensor(address)

    {rel_moisture_sensor, capacity_sensor}
  end

end
