<?php

namespace App\Database;

use Illuminate\Database\PostgresConnection;
use Illuminate\Support\Facades\Http;
use Illuminate\Database\QueryException;

class SupabaseConnection extends PostgresConnection
{
    /**
     * Create a new database connection instance.
     *
     * @param  array  $config
     */
    public function __construct(array $config)
    {
        $this->config = $config;

        // Use PostgreSQL grammar and post-processor
        $this->useDefaultQueryGrammar();
        $this->useDefaultPostProcessor();
    }

    /**
     * Get the default query grammar instance.
     *
     * @return \Illuminate\Database\Query\Grammars\PostgresGrammar
     */
    protected function getDefaultQueryGrammar()
    {
        return $this->withTablePrefix(new \Illuminate\Database\Query\Grammars\PostgresGrammar($this));
    }

    /**
     * Get the default post processor instance.
     *
     * @return \Illuminate\Database\Query\Processors\PostgresProcessor
     */
    protected function getDefaultPostProcessor()
    {
        return new \Illuminate\Database\Query\Processors\PostgresProcessor;
    }

    /**
     * Get the raw PDO connection.
     *
     * @return null
     */
    public function getPdo()
    {
        return null;
    }

    /**
     * Get the raw PDO connection for reading.
     *
     * @return null
     */
    public function getReadPdo()
    {
        return null;
    }

    /**
     * Run a select statement against the database.
     *
     * @param  string  $query
     * @param  array  $bindings
     * @param  bool  $useReadPdo
     * @param  array  $fetchUsing
     * @return array
     */
    public function select($query, $bindings = [], $useReadPdo = true, array $fetchUsing = [])
    {
        return $this->runQuery($query, $bindings, 'select');
    }

    /**
     * Run an insert statement against the database.
     *
     * @param  string  $query
     * @param  array  $bindings
     * @return bool
     */
    public function insert($query, $bindings = [])
    {
        return $this->runQuery($query, $bindings, 'insert');
    }

    /**
     * Run an update statement against the database.
     *
     * @param  string  $query
     * @param  array  $bindings
     * @return int
     */
    public function update($query, $bindings = [])
    {
        return $this->runQuery($query, $bindings, 'update');
    }

    /**
     * Run a delete statement against the database.
     *
     * @param  string  $query
     * @param  array  $bindings
     * @return int
     */
    public function delete($query, $bindings = [])
    {
        return $this->runQuery($query, $bindings, 'delete');
    }

    /**
     * Execute an SQL statement and return the boolean result.
     *
     * @param  string  $query
     * @param  array  $bindings
     * @return bool
     */
    public function statement($query, $bindings = [])
    {
        return $this->runQuery($query, $bindings, 'statement');
    }

    /**
     * Run an SQL statement and get the number of affected rows.
     *
     * @param  string  $query
     * @param  array  $bindings
     * @return int
     */
    public function affectingStatement($query, $bindings = [])
    {
        return $this->runQuery($query, $bindings, 'affectingStatement');
    }

    /**
     * Run a raw, unprepared query against the connection.
     *
     * @param  string  $query
     * @return bool
     */
    public function unprepared($query)
    {
        return $this->runQuery($query, [], 'statement');
    }

    /**
     * Start a new database transaction.
     *
     * @return void
     */
    public function beginTransaction()
    {
        $this->transactions++;
        $this->fireConnectionEvent('beganTransaction');
    }

    /**
     * Commit the active database transaction.
     *
     * @return void
     */
    public function commit()
    {
        $this->transactions = max(0, $this->transactions - 1);
        $this->fireConnectionEvent('committed');
    }

    /**
     * Rollback the active database transaction.
     *
     * @param  int|null  $toLevel
     * @return void
     */
    public function rollBack($toLevel = null)
    {
        $this->transactions = max(0, $this->transactions - 1);
        $this->fireConnectionEvent('rollingBack');
    }

    /**
     * Interpolate query bindings to create a full raw SQL query.
     *
     * @param  string  $query
     * @param  array  $bindings
     * @return string
     */
    protected function interpolateQuery(string $query, array $bindings): string
    {
        if (empty($bindings)) {
            return $query;
        }

        $indexed = $bindings;

        $sql = preg_replace_callback('/\?/', function ($match) use (&$indexed) {
            if (empty($indexed)) {
                return '?';
            }
            $val = array_shift($indexed);

            if (is_null($val)) {
                return 'NULL';
            }
            if (is_bool($val)) {
                return $val ? 'true' : 'false';
            }
            if (is_numeric($val)) {
                return $val;
            }
            if ($val instanceof \DateTimeInterface) {
                $val = $val->format('Y-m-d H:i:s');
            }

            // Escape single quotes for safety
            return "'" . str_replace("'", "''", (string) $val) . "'";
        }, $query);

        return $sql;
    }

    /**
     * Run the query via Supabase RPC endpoint.
     *
     * @param  string  $query
     * @param  array  $bindings
     * @param  string  $type
     * @return mixed
     *
     * @throws \Illuminate\Database\QueryException
     */
    protected function runQuery(string $query, array $bindings, string $type)
    {
        $sql = $this->interpolateQuery($query, $bindings);

        try {
            // Send query to the custom execute_sql Postgres function
            $response = Http::supabase(true) // Uses service key for admin database privileges
                ->post('rest/v1/rpc/execute_sql', [
                    'sql_query' => $sql,
                ]);

            if ($response->failed()) {
                $errorData = $response->json();
                $errorMessage = $errorData['message'] ?? $response->body() ?? 'HTTP Request Failed';
                throw new \Exception($errorMessage);
            }

            $data = $response->json();

            // Check if our Postgres function caught an error inside the PL/pgSQL block
            if (is_array($data) && isset($data['error_message'])) {
                throw new \Exception($data['error_message'] . ' (Code: ' . ($data['error_code'] ?? 'N/A') . ')');
            }

            if ($type === 'select') {
                // Return array of stdClass objects
                return array_map(function ($row) {
                    return (object) $row;
                }, $data ?? []);
            }

            if ($type === 'insert') {
                return true;
            }

            if ($type === 'update' || $type === 'delete' || $type === 'affectingStatement') {
                // If execute_sql returned affected rows metadata, use it, else default to 1
                return $data['affected_rows'] ?? 1;
            }

            return true;
        } catch (\Exception $e) {
            throw new QueryException(
                $this->getName(),
                $sql,
                $bindings,
                $e
            );
        }
    }
}
