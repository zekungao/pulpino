// `define EXIT_SUCCESS  0
// `define EXIT_FAIL     1
// `define EXIT_ERROR   -1

package pkg_exit_status;

typedef enum {
  SUCCESS = 0,
  FAIL    = 1,
  ERROR   = -1
} Status;

endpackage

interface ExitStatus();
  logic  done;
  pkg_exit_status::Status status;

  initial begin
    status = pkg_exit_status::ERROR;
    done = 1'b0;
  end

  task Done(input pkg_exit_status::Status status_i);
    status = status_i;
    done = 1'b1;
  endtask

  task Wait();
    wait(done);
  endtask

endinterface
